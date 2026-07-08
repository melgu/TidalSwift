//
//  Login.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import Combine

extension Session {
	/// Margin before actual expiration to trigger a refresh (5 minutes)
	private static let tokenRefreshMargin: TimeInterval = 5 * 60
	
	public func login(refreshToken: String, clientID: String) async throws {
		config.refreshToken = refreshToken
		config.clientID = clientID
		try await refreshAccessToken()
		try await populateVariablesForAccessToken()
	}

	private func setAccessToken(_ accessToken: String, refreshToken: String?, expiresIn: Int) {
		var token = accessToken
		if !token.hasPrefix("Bearer ") {
			token = "Bearer " + token
		}

		config.accessToken = token
		if let refreshToken {
			config.refreshToken = refreshToken
		}

		config.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
	}

	public func populateVariablesForAccessToken() async throws {
		let url = URL(string: "https://login.tidal.com/oauth2/me")!
		let response: Response
		do {
			response = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		} catch {
			throw SessionError.network(underlying: error)
		}
		if response.statusCode == 401 || response.statusCode == 403 {
			throw SessionError.invalidCredentials(description: nil)
		}
		guard let user = try? JSONDecoder.custom.decode(LoginUser.self, from: response.data) else {
			throw SessionError.unexpectedResponse
		}
		self.countryCode = user.countryCode
		self.userId = user.userId
		self.favorites = Favorites(session: self, userId: user.userId)
	}
	
	public enum AuthorizationState {
		case waiting
		case pending(loginUrl: URL, expiration: Date)
		case success
		case failure(Error)
	}
	
	enum AuthorizationError: Error {
		case deviceAuthorizationFailed
		case pollingFailed
		case expiredToken
		case unknown
	}
	
	public func startAuthorization() -> CurrentValueSubject<AuthorizationState, Never> {
		let subject = CurrentValueSubject<AuthorizationState, Never>(.waiting)
		
		let url = URL(string: "\(AuthInformation.AuthLocation)/device_authorization")!
		let parameters: [String: String] = ["client_id": AuthInformation.OAuthClientID,
											"scope": AuthInformation.scope]
		
		Task {
			do {
				let response: DeviceAuthorizationResponse = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
				
				let expiration = Date().addingTimeInterval(TimeInterval(response.expiresIn))
				let loginUrlString = "https://\(response.verificationUriComplete.absoluteString)"
				let loginUrl = URL(string: loginUrlString)!
				subject.send(.pending(loginUrl: loginUrl, expiration: expiration))
				
				startAuthorizationPolling(deviceCode: response.deviceCode, subject: subject)
			} catch {
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
			}
		}
		
		return subject
	}
	
	private func startAuthorizationPolling(deviceCode: UUID, subject: CurrentValueSubject<AuthorizationState, Never>) {
		let url = URL(string: "\(AuthInformation.AuthLocation)/token")!
		let parameters: [String: String] = [
			"client_id": AuthInformation.OAuthClientID,
			"client_secret": AuthInformation.OAuthClientSecret,
			"device_code": deviceCode.uuidString.lowercased(),
			"grant_type": "urn:ietf:params:oauth:grant-type:device_code",
			"scope": AuthInformation.scope
		]
		
		Task {
			try await Task.sleep(for: .seconds(2))
			authorizationPoll(url: url, parameters: parameters, subject: subject)
		}
	}
	
	private func authorizationPoll(url: URL, parameters: [String: String], subject: CurrentValueSubject<AuthorizationState, Never>) {
		Task {
			do {
				let response = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
				if let successResponse = try? JSONDecoder.custom.decode(TokenSuccessResponse.self, from: response.data) {
					setAccessToken(successResponse.accessToken, refreshToken: successResponse.refreshToken, expiresIn: successResponse.expiresIn)
					config.clientID = AuthInformation.OAuthClientID
					do {
						try await populateVariablesForAccessToken()
						subject.send(.success)
					} catch {
						subject.send(.failure(error))
					}
				} else if let errorResponse = try? JSONDecoder.custom.decode(TokenErrorResponse.self, from: response.data) {
					switch errorResponse.error {
					case "authorization_pending":
						print("Auth pending")
						try await Task.sleep(for: .seconds(2))
						authorizationPoll(url: url, parameters: parameters, subject: subject)
					case "expired_token":
						print("Expired token")
						subject.send(.failure(AuthorizationError.expiredToken))
					default:
						print("Polling failed")
						subject.send(.failure(AuthorizationError.pollingFailed))
					}
				} else {
					subject.send(.failure(AuthorizationError.pollingFailed))
				}
			} catch {
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
			}
		}
	}
	
	/// Refreshes the access token. Concurrent calls share a single refresh
	/// request instead of each hitting the auth server.
	public func refreshAccessToken() async throws {
		if let activeTokenRefresh {
			return try await activeTokenRefresh.value
		}
		let task = Task {
			defer { activeTokenRefresh = nil }
			try await performAccessTokenRefresh()
		}
		activeTokenRefresh = task
		return try await task.value
	}

	private func performAccessTokenRefresh() async throws {
		print("refreshAccessToken")
		guard !config.refreshToken.isEmpty else {
			throw SessionError.notLoggedIn
		}
		let url = URL(string: "\(AuthInformation.AuthLocation)/token")!
		var parameters: [String: String] = [
			"client_id": config.clientID,
			"refresh_token": config.refreshToken,
			"grant_type": "refresh_token",
			"scope": AuthInformation.scope
		]
		// The built-in client is confidential: Tidal rejects its refresh requests without the secret
		if config.clientID == AuthInformation.OAuthClientID {
			parameters["client_secret"] = AuthInformation.OAuthClientSecret
		}

		let response: Response
		do {
			response = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
		} catch {
			throw SessionError.network(underlying: error)
		}

		if let successResponse = try? JSONDecoder.custom.decode(TokenSuccessResponse.self, from: response.data) {
			setAccessToken(successResponse.accessToken, refreshToken: successResponse.refreshToken, expiresIn: successResponse.expiresIn)
			saveConfig()
			print("Access token refreshed. New expiration: \(config.tokenExpirationDate?.description ?? "unknown")")
		} else if let errorResponse = try? JSONDecoder.custom.decode(TokenErrorResponse.self, from: response.data) {
			throw SessionError.invalidCredentials(description: errorResponse.errorDescription)
		} else {
			throw SessionError.unexpectedResponse
		}
	}

	/// Refreshes the access token if it is expired or about to expire.
	public func refreshAccessTokenIfNeeded() async throws {
		guard !config.refreshToken.isEmpty else { return }
		guard let expirationDate = config.tokenExpirationDate else {
			// No expiration date recorded — refresh to be safe
			try await refreshAccessToken()
			return
		}
		if Date() >= expirationDate.addingTimeInterval(-Session.tokenRefreshMargin) {
			try await refreshAccessToken()
		}
	}
}

extension Session {
	public func logout() {
		activeTokenRefresh?.cancel()
		activeTokenRefresh = nil
		deletePersistentInformation()
		config = Config(accessToken: "", refreshToken: "", clientID: "", offlineAudioQuality: .high, urlType: .streaming)
	}
}
