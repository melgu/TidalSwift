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
	var content: Data?
	var ok: Bool
}

enum HttpMethod {
	case get
	case post
	case delete
}

func encodeParameters(_ parameters: [String: String]) -> String {
	let queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
	var components = URLComponents()
	components.queryItems = queryItems
	return components.percentEncodedQuery ?? ""
}

func request(method: HttpMethod, url: URL, parameters: [String: String]) -> Response {
	var request = URLRequest(url: url)
	request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
	
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
//	print("Network Request with URL: \(request.url!.absoluteString)")
	
	var networkResponse = Response(statusCode: nil, content: nil, ok: false)
	
	let semaphore = DispatchSemaphore(value: 0)
	let task = URLSession.shared.dataTask(with: request) { data, response, error in
		guard let data = data,
			let response = response as? HTTPURLResponse,
			error == nil else {								// check for fundamental networking error
//				print("error", error ?? "Unknown error")
				semaphore.signal()
				return
		}
		
		guard (200 ... 299) ~= response.statusCode else {	// check for http errors
//			print("statusCode should be 2xx, but is \(response.statusCode)")
//			print("response = \(response)")
			networkResponse.statusCode = response.statusCode
			semaphore.signal()
			return
		}
		
//		print("responseString = \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
		networkResponse = Response(statusCode: response.statusCode, content: data, ok: true)
		semaphore.signal()
	}
	task.resume()
	_ = semaphore.wait(timeout: DispatchTime.distantFuture)
	
	return networkResponse
}

func get(url: URL, parameters: [String: String]) -> Response {
	return request(method: .get, url: url, parameters: parameters)
}

func post(url: URL, parameters: [String: String]) -> Response {
	return request(method: .post, url: url, parameters: parameters)
}

func asyncGet(url: URL, parameters: [String: String],
			  completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .userInitiated).async {
		let response = request(method: .get, url: url, parameters: parameters)
		completionHandler(response)
	}
}

func asyncPost(url: URL, parameters: [String: String],
			   completionHandler: @escaping (Response) -> Void) {
	DispatchQueue.global(qos: .userInitiated).async {
		let response = request(method: .post, url: url, parameters: parameters)
		completionHandler(response)
	}
}
