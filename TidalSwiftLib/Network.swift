//
//  Network.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

struct Response {
	var statusCode: Int?
	var etag: Int?
	var content: Data?
	var ok: Bool
}

class Network {
	
	// MARK: - Queries
	
	enum HttpMethod {
		case get
		case post
		case delete
	}
	
	private class func encodeParameters(_ parameters: [String: String]) -> String {
		let queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
		var components = URLComponents()
		components.queryItems = queryItems
		return components.percentEncodedQuery ?? ""
	}
	
	private class func request(method: HttpMethod, url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) -> Response {
		var request = URLRequest(url: url)
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		if let accessToken = accessToken {
			request.setValue(accessToken, forHTTPHeaderField: "Authorization")
		}
		if let xTidalToken = xTidalToken {
			request.setValue(xTidalToken, forHTTPHeaderField: "X-Tidal-Token")
		}
		if let etag = etag {
			request.setValue(#""\#(etag)""#, forHTTPHeaderField: "If-None-Match")
		}
		
		switch method {
		case .get:
			request.httpMethod = "GET"
			// If GET or DELETE, parameters are part of the URL
			let urlString = request.url!.absoluteString + "?" + encodeParameters(parameters)
			request.url = URL(string: urlString)
		case .post:
			request.httpMethod = "POST"
			// If POST or DELETE, parameters are part of the body
			request.httpBody = encodeParameters(parameters).data(using: String.Encoding.utf8)
		case .delete:
			request.httpMethod = "DELETE"
			// If GET or DELETE, parameters are part of the URL
			let urlString = request.url!.absoluteString + "?" + encodeParameters(parameters)
			request.url = URL(string: urlString)
		}
			print("=== Network Request ===")
			print("\(request.httpMethod!) Request with URL: \(request.url!.absoluteString)")
			print("Headers: \(request.allHTTPHeaderFields!)")
			if let httpBody = request.httpBody {
				print("Body: \(String(data: httpBody, encoding: String.Encoding.utf8)!)")
			}
			print("=======================")
		
		var networkResponse = Response(statusCode: nil, etag: nil, content: nil, ok: false)
		
		let semaphore = DispatchSemaphore(value: 0)
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let response = response as? HTTPURLResponse else {
				semaphore.signal()
				return
			}
			
			networkResponse.statusCode = response.statusCode
			
			guard let data = data else {
				semaphore.signal()
				return
			}
			
			networkResponse.content = data
			
			guard error == nil else { // check for fundamental networking error
				semaphore.signal()
				return
			}
			
			guard (200..<299) ~= response.statusCode else {	// check for http errors
				semaphore.signal()
				return
			}
			
			networkResponse.ok = true
			
			// Getting the Etag if it exists
			var etag: Int?
			if let etagString = response.allHeaderFields["Etag"] as? String {
				var etagSubString = etagString.dropFirst()
				etagSubString = etagSubString.dropLast()
				etag = Int(etagSubString)
			}
			
			print("responseString = \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
			networkResponse = Response(statusCode: response.statusCode, etag: etag, content: data, ok: true)
			semaphore.signal()
		}
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		return networkResponse
	}
	
	class func get(url: URL, parameters: [String: String],
				   accessToken: String?, xTidalToken: String?) -> Response {
		request(method: .get, url: url, parameters: parameters,
				accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	class func post(url: URL, parameters: [String: String], etag: Int? = nil,
					accessToken: String?, xTidalToken: String?) -> Response {
		request(method: .post, url: url, parameters: parameters, etag: etag,
				accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	class func delete(url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) -> Response {
		request(method: .delete, url: url, parameters: parameters, etag: etag,
				accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	class func asyncGet(url: URL, parameters: [String: String],
						accessToken: String?, xTidalToken: String?,
						completionHandler: @escaping (Response) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let response = self.request(method: .get, url: url, parameters: parameters,
										accessToken: accessToken, xTidalToken: xTidalToken)
			completionHandler(response)
		}
	}
	
	class func asyncPost(url: URL, parameters: [String: String],
						 etag: Int? = nil, accessToken: String?, xTidalToken: String?,
						 completionHandler: @escaping (Response) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let response = self.request(method: .post, url: url, parameters: parameters, etag: etag,
										accessToken: accessToken, xTidalToken: xTidalToken)
			completionHandler(response)
		}
	}
	
	class func asyncDelete(url: URL, parameters: [String: String], etag: Int? = nil,
						   accessToken: String?, xTidalToken: String?,
						   completionHandler: @escaping (Response) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let response = self.request(method: .delete, url: url, parameters: parameters,
										etag: etag, accessToken: accessToken, xTidalToken: xTidalToken)
			completionHandler(response)
		}
	}
	
	// MARK: - Downloads
	
	// Path Structure example: path/to/file -> [path, to, file]. Cannot be empty
	class func download(_ url: URL, path: URL, overwrite: Bool = false) -> Response {
		var networkResponse = Response(statusCode: nil, ok: false)
		
		do {
//			print("=== Network Download ===")
//			print("Download URL: \(url)")
//			print("Temp Local URL: \(dataUrl)")
//			print("Final Local URL: \(path)")
//			print("=======================")
			
			try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
			
			// No need to download if we're not overwriting and file exists
			if !overwrite && FileManager.default.fileExists(atPath: path.relativePath) {
				return Response(ok: true)
			}
		} catch {
			displayError(title: "Download Error", content: "File Error: \(error)")
			return networkResponse
		}
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let downloadTask = URLSession.shared.downloadTask(with: url) { dataUrlOrNil, responseOrNil, error in
			
			guard let dataUrl = dataUrlOrNil,
				let response = responseOrNil as? HTTPURLResponse,
				error == nil else { // check for fundamental networking error
//					print("error", error ?? "Unknown error")
					displayError(title: "Download Error",
								 content: "Error: \(error!). URL: \(url)")
					semaphore.signal()
					return
			}
			
			guard (200..<299) ~= response.statusCode else {	// check for http errors
//				print("statusCode should be 2xx, but is \(response.statusCode)")
//				print("response = \(response)")
				displayError(title: "Download Error",
							 content: "statusCode should be 2xx, but is \(response.statusCode).")
				networkResponse.statusCode = response.statusCode
				semaphore.signal()
				return
			}
			
			do {
				// If we want to overwrite and the file exists, delete the existing file
				if overwrite && FileManager.default.fileExists(atPath: path.relativePath) {
					try FileManager.default.removeItem(at: path)
				}
				try FileManager.default.moveItem(at: dataUrl, to: path)
//				print("Path: \(path)")
			} catch {
				displayError(title: "Download Error",
							 content: "Failed to move file from \(dataUrl) to \(path). File Error: \(error).")
			}
			networkResponse = Response(statusCode: response.statusCode, ok: true)
			semaphore.signal()
		}
		downloadTask.resume()
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		return networkResponse
	}
	
	class func asyncDownload(_ url: URL, path: URL, completionHandler: @escaping (Response) -> Void) {
		DispatchQueue.global(qos: .background).async {
			let response = self.download(url, path: path)
			completionHandler(response)
		}
	}
}
