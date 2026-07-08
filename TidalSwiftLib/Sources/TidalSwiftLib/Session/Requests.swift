//
//  Requests.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 07.07.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

// Authenticated requests. These refresh the access token beforehand when it is
// expired (or about to expire) and retry once if the server rejects it anyway.
extension Session {
	func get(url: URL, parameters: [String: String]) async throws -> Response {
		try await authenticatedRequest(method: .get, url: url, parameters: parameters)
	}

	func get<Result: Decodable>(url: URL, parameters: [String: String], decoder: JSONDecoder = .custom) async throws -> Result {
		let response = try await authenticatedRequest(method: .get, url: url, parameters: parameters)
		return try decoder.decode(Result.self, from: response.data)
	}

	func post(url: URL, parameters: [String: String], etag: Int? = nil) async throws -> Response {
		try await authenticatedRequest(method: .post, url: url, parameters: parameters, etag: etag)
	}

	func post<Result: Decodable>(url: URL, parameters: [String: String], etag: Int? = nil, decoder: JSONDecoder = .custom) async throws -> Result {
		let response = try await authenticatedRequest(method: .post, url: url, parameters: parameters, etag: etag)
		return try decoder.decode(Result.self, from: response.data)
	}

	func delete(url: URL, parameters: [String: String], etag: Int? = nil) async throws -> Response {
		try await authenticatedRequest(method: .delete, url: url, parameters: parameters, etag: etag)
	}

	private func authenticatedRequest(method: Network.HttpMethod, url: URL, parameters: [String: String], etag: Int? = nil) async throws -> Response {
		// A failed proactive refresh isn't fatal here: the request itself
		// surfaces the definitive error (network failure or 401 below)
		try? await refreshAccessTokenIfNeeded()
		let response = try await Network.request(method: method, url: url, parameters: parameters, etag: etag, accessToken: config.accessToken, xTidalToken: config.apiToken)
		guard response.statusCode == 401 else {
			return response
		}
		try await refreshAccessToken()
		return try await Network.request(method: method, url: url, parameters: parameters, etag: etag, accessToken: config.accessToken, xTidalToken: config.apiToken)
	}
}
