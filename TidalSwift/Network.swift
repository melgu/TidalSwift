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

// MARK: - Queries

enum HttpMethod {
	case get
	case post
	case delete
}

private func encodeParameters(_ parameters: [String: String]) -> String {
	let queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
	var components = URLComponents()
	components.queryItems = queryItems
	return components.percentEncodedQuery ?? ""
}

private func request(method: HttpMethod, url: URL, parameters: [String: String], etag: Int? = nil) -> Response {
	var request = URLRequest(url: url)
	request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
//	print("=== Network Request ===")
//	print("\(request.httpMethod!) Request with URL: \(request.url!.absoluteString)")
//	print("Headers: \(request.allHTTPHeaderFields!)")
//	if request.httpBody != nil {
//		print("Body: \(String(data: request.httpBody!, encoding: String.Encoding.utf8)!)")
//	}
//	print("=======================")
	
	var networkResponse = Response(statusCode: nil, etag: nil, content: nil, ok: false)
	
	let semaphore = DispatchSemaphore(value: 0)
	let task = URLSession.shared.dataTask(with: request) { data, response, error in
		guard let data = data,
			let response = response as? HTTPURLResponse,
			error == nil else { // check for fundamental networking error
//				print("error", error ?? "Unknown error")
				semaphore.signal()
				return
		}
		
		guard (200..<299) ~= response.statusCode else {	// check for http errors
//			print("statusCode should be 2xx, but is \(response.statusCode)")
//			print("response = \(response)")
			networkResponse.statusCode = response.statusCode
			semaphore.signal()
			return
		}
		
		// Getting the Etag if it exists
		var etag: Int?
		if let etagString = response.allHeaderFields["Etag"] as? String {
			var etagSubString = etagString.dropFirst()
			etagSubString = etagSubString.dropLast()
			etag = Int(String(etagSubString))
		}
		
//		print("responseString = \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
		networkResponse = Response(statusCode: response.statusCode, etag: etag, content: data, ok: true)
		semaphore.signal()
	}
	task.resume()
	_ = semaphore.wait(timeout: DispatchTime.distantFuture)
	
	return networkResponse
}

func get(url: URL, parameters: [String: String]) -> Response {
	return request(method: .get, url: url, parameters: parameters)
}

func post(url: URL, parameters: [String: String], etag: Int? = nil) -> Response {
	return request(method: .post, url: url, parameters: parameters, etag: etag)
}

func delete(url: URL, parameters: [String: String], etag: Int? = nil) -> Response {
	return request(method: .delete, url: url, parameters: parameters, etag: etag)
}

func asyncGet(url: URL, parameters: [String: String],
			  completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .userInitiated).async {
		let response = request(method: .get, url: url, parameters: parameters)
		completionHandler(response)
	}
}

func asyncPost(url: URL, parameters: [String: String], etag: Int? = nil,
			   completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .userInitiated).async {
		let response = request(method: .post, url: url, parameters: parameters, etag: etag)
		completionHandler(response)
	}
}

func asyncDelete(url: URL, parameters: [String: String], etag: Int? = nil,
			   completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .userInitiated).async {
		let response = request(method: .delete, url: url, parameters: parameters, etag: etag)
		completionHandler(response)
	}
}

// MARK: - Downloads

enum DownloadLocation {
	case downloads
	case music
}

// Path Structure example: path/to/file -> [path, to, file]. Cannot be empty
func download(_ url: URL, baseLocation: DownloadLocation, targetPath: String, name: String) -> Response {
	var networkResponse = Response(statusCode: nil, ok: false)
	
	if !targetPath.isEmpty {
		if URL(string: targetPath) == nil {
			displayError(title: "Download Error", content: "Target Path '\(targetPath)' is not valid")
			return networkResponse
		}
	}
	if URL(string: name) == nil {
		displayError(title: "Download Error", content: "Name '\(name)' is not valid")
		return networkResponse
	}
	
	let semaphore = DispatchSemaphore(value: 0)
	
	let downloadTask = URLSession.shared.downloadTask(with: url) {
		dataUrlOrNil, responseOrNil, error in
		
		guard let dataUrl = dataUrlOrNil,
			let response = responseOrNil as? HTTPURLResponse,
			error == nil else { // check for fundamental networking error
//				print("error", error ?? "Unknown error")
				semaphore.signal()
				return
		}
		
		guard (200..<299) ~= response.statusCode else {	// check for http errors
//			print("statusCode should be 2xx, but is \(response.statusCode)")
//			print("response = \(response)")
			networkResponse.statusCode = response.statusCode
			semaphore.signal()
			return
		}
		
		do {
			var path: URL
			switch baseLocation {
			case .downloads:
				path = try FileManager.default.url(for: .downloadsDirectory,
														   in: .userDomainMask,
														   appropriateFor: nil,
														   create: false)
			case .music:
				path = try FileManager.default.url(for: .musicDirectory,
														   in: .userDomainMask,
														   appropriateFor: nil,
														   create: false)
			@unknown default:
				return
			}
			
			path.appendPathComponent(targetPath)
			
//			print("=== Network Download ===")
//			print("Download URL: \(url)")
//			print("Temp Local URL: \(dataUrl)")
//			print("Final Local URL: \(path)")
//			print("=======================")
			
			try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
			path.appendPathComponent(name)
			try FileManager.default.moveItem(at: dataUrl, to: path)
		} catch {
			displayError(title: "Download Error", content: "File Error: \(error)")
		}
		networkResponse = Response(statusCode: response.statusCode, ok: true)
		semaphore.signal()
	}
	downloadTask.resume()
	_ = semaphore.wait(timeout: DispatchTime.distantFuture)
	
	return networkResponse
}

func asyncDownload(_ url: URL, baseLocation: DownloadLocation, targetPath: String, name: String,
				   completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .background).async {
		let response = download(url, baseLocation: baseLocation, targetPath: targetPath, name: name)
		completionHandler(response)
	}
}

