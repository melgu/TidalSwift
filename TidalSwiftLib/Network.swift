//
//  Network.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

struct Response {
	let data: Data
	let etag: Int?
}

enum Network {}

extension Network {
	
	// MARK: - Queries
	
	enum HttpMethod {
		case get
		case post
		case delete
	}
	
	private static func encodeParameters(_ parameters: [String: String]) -> String {
		let queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
		var components = URLComponents()
		components.queryItems = queryItems
		return components.percentEncodedQuery ?? ""
	}
	
	private static func request(method: HttpMethod, url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) async throws -> Response {
		var request = URLRequest(url: url)
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		if let accessToken = accessToken {
			request.setValue(accessToken, forHTTPHeaderField: "Authorization")
		}
		if let xTidalToken = xTidalToken {
			request.setValue(xTidalToken, forHTTPHeaderField: "X-Tidal-Token")
		}
		if let etag = etag {
			request.setValue("\"\(etag)\"", forHTTPHeaderField: "If-None-Match")
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
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		// Get the Etag if it exists
		var etag: Int?
		if let httpURLResponse = response as? HTTPURLResponse,
			let etagString = httpURLResponse.allHeaderFields["Etag"] as? String {
			let etagSubString = etagString.dropFirst().dropLast()
			etag = Int(etagSubString)
		}
		
		print("responseString = \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
		
		return Response(data: data, etag: etag)
	}
	
	static func get(url: URL, parameters: [String: String], accessToken: String?, xTidalToken: String?) async throws -> Response {
		try await request(method: .get, url: url, parameters: parameters, accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	static func get<Result: Decodable>(url: URL, parameters: [String: String], accessToken: String?, xTidalToken: String?, decoder: JSONDecoder = .custom) async throws -> Result {
		let response = try await request(method: .get, url: url, parameters: parameters, accessToken: accessToken, xTidalToken: xTidalToken)
		return try decoder.decode(Result.self, from: response.data)
	}
	
	static func post(url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) async throws -> Response {
		try await request(method: .post, url: url, parameters: parameters, etag: etag, accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	static func post<Result: Decodable>(url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?, decoder: JSONDecoder = .custom) async throws -> Result {
		let response = try await request(method: .post, url: url, parameters: parameters, etag: etag, accessToken: accessToken, xTidalToken: xTidalToken)
		return try decoder.decode(Result.self, from: response.data)
	}
	
	static func delete(url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) async throws -> Response {
		try await request(method: .delete, url: url, parameters: parameters, etag: etag, accessToken: accessToken, xTidalToken: xTidalToken)
	}
	
	// MARK: - Downloads
	
	// Path Structure example: path/to/file -> [path, to, file]. Cannot be empty
	static func download(_ url: URL, path: URL, overwrite: Bool = false) async throws {
//		print("=== Network Download ===")
//		print("Download URL: \(url)")
//		print("Temp Local URL: \(dataUrl)")
//		print("Final Local URL: \(path)")
//		print("=======================")
		
		try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
		
		// No need to download if we're not overwriting and file exists
		if !overwrite && FileManager.default.fileExists(atPath: path.relativePath) {
			return
		}
		
		let (downloadURL, _) = try await URLSession.shared.download(from: url)
		
		// If we want to overwrite and the file exists, delete the existing file
		if overwrite && FileManager.default.fileExists(atPath: path.relativePath) {
			try FileManager.default.removeItem(at: path)
		}
		try FileManager.default.moveItem(at: downloadURL, to: path)
	}
}
