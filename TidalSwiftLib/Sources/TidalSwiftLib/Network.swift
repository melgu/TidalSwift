//
//  Network.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import OSLog

private let logger = Logger(category: "Network")

struct Response {
	let data: Data
	let statusCode: Int?
	let etag: Int?
}

public enum Network {}

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
	
	#if DEBUG
	private static let secretKeys = "access_token|refresh_token|id_token|client_secret|device_code|deviceCode|user_code|userCode"
	private static let formSecretRegex = try! NSRegularExpression(pattern: "\\b(\(secretKeys))=[^&]*")
	private static let jsonSecretRegex = try! NSRegularExpression(pattern: "\"(\(secretKeys))\"\\s*:\\s*\"[^\"]*\"")
	
	/// Blanks secrets in form-encoded request bodies and JSON responses, so they can be logged
	private static func redactingSecrets(_ string: String) -> String {
		let formRedacted = formSecretRegex.stringByReplacingMatches(in: string, range: NSRange(string.startIndex..., in: string), withTemplate: "$1=<redacted>")
		return jsonSecretRegex.stringByReplacingMatches(in: formRedacted, range: NSRange(formRedacted.startIndex..., in: formRedacted), withTemplate: "\"$1\":\"<redacted>\"")
	}
	#endif
	
	static func request(method: HttpMethod, url: URL, parameters: [String: String], etag: Int? = nil, accessToken: String?, xTidalToken: String?) async throws -> Response {
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
			request.httpBody = encodeParameters(parameters).data(using: .utf8)
		case .delete:
			request.httpMethod = "DELETE"
			// If GET or DELETE, parameters are part of the URL
			let urlString = request.url!.absoluteString + "?" + encodeParameters(parameters)
			request.url = URL(string: urlString)
		}
		logger.debug("\(request.httpMethod!, privacy: .public) \(request.url!.absoluteString)")
		// Private, as they hold the access token
		logger.debug("Headers: \(request.allHTTPHeaderFields ?? [:], privacy: .private)")
		#if DEBUG
		if let httpBody = request.httpBody, let body = String(data: httpBody, encoding: .utf8) {
			logger.debug("Body: \(redactingSecrets(body))")
		}
		#endif
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		let statusCode = (response as? HTTPURLResponse)?.statusCode
		
		// Get the Etag if it exists
		var etag: Int?
		if let httpURLResponse = response as? HTTPURLResponse,
			let etagString = httpURLResponse.allHeaderFields["Etag"] as? String {
			let etagSubString = etagString.dropFirst().dropLast()
			etag = Int(etagSubString)
		}
		
		#if DEBUG
		if let responseString = String(data: data, encoding: .utf8) {
			logger.debug("Response \(statusCode ?? 0, privacy: .public): \(redactingSecrets(responseString))")
		} else {
			logger.debug("Response \(statusCode ?? 0, privacy: .public) is not UTF8")
		}
		#endif
		
		return Response(data: data, statusCode: statusCode, etag: etag)
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
	public static func download(_ url: URL, path: URL, overwrite: Bool = false) async throws {
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
		
		let (downloadURL, response) = try await URLSession.shared.download(from: url)
		
		// Otherwise an error page, e.g. for an expired URL, would be stored as the file
		if let statusCode = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(statusCode) {
			try? FileManager.default.removeItem(at: downloadURL)
			throw URLError(.badServerResponse)
		}
		
		// If we want to overwrite and the file exists, delete the existing file
		if overwrite && FileManager.default.fileExists(atPath: path.relativePath) {
			try FileManager.default.removeItem(at: path)
		}
		try FileManager.default.moveItem(at: downloadURL, to: path)
	}
}
