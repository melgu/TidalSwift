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
	
	public func login(refreshToken: String, clientID: String) async -> Bool {
		config.refreshToken = refreshToken
		config.clientID = clientID
		await refreshAccessToken()
		return await populateVariablesForAccessToken()
	}
	
	private func setAccessToken(_ accessToken: String, refreshToken: String?, expiresIn: Int) async -> Bool {
		var token = accessToken
		if !token.hasPrefix("Bearer ") {
			token = "Bearer " + token
		}
		
		config.accessToken = token
		if let refreshToken {
			config.refreshToken = refreshToken
		}
		
		config.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
		
		await refreshAccessTokenIfNeeded()
		return await populateVariablesForAccessToken()
	}
	
	public func populateVariablesForAccessToken() async -> Bool {
		let url = URL(string: "https://login.tidal.com/oauth2/me")!
		do {
			let response: LoginUser = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			self.countryCode = response.countryCode
			self.userId = response.userId
			self.favorites = Favorites(session: self, userId: response.userId)
			return true
		} catch {
			return false
		}
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
					if await setAccessToken(successResponse.accessToken, refreshToken: successResponse.refreshToken, expiresIn: successResponse.expiresIn) {
						config.clientID = AuthInformation.OAuthClientID
						scheduleAccessTokenRefresh()
						subject.send(.success)
					} else {
						subject.send(.failure(AuthorizationError.unknown))
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
	
	public func refreshAccessToken() async {
		print("refreshAccessToken")
		let url = URL(string: "\(AuthInformation.AuthLocation)/token")!
		let parameters: [String: String] = [
			"client_id": config.clientID,
			"refresh_token": config.refreshToken,
			"grant_type": "refresh_token",
			"scope": AuthInformation.scope
		]
		
		do {
			let response: TokenSuccessResponse = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
			await setAccessToken(response.accessToken, refreshToken: nil, expiresIn: response.expiresIn)
			scheduleAccessTokenRefresh()
			print("Access token refreshed. New expiration: \(config.tokenExpirationDate?.description ?? "unknown")")
		} catch {
			displayError(title: "Refresh Access Token failed", content: "Error: \(error)")
		}
	}

	/// Refreshes the access token if it is expired or about to expire.
	public func refreshAccessTokenIfNeeded() async {
		guard config.refreshToken != nil else { return }
		guard let expirationDate = config.tokenExpirationDate else {
			// No expiration date recorded — refresh to be safe
			await refreshAccessToken()
			return
		}
		if Date() >= expirationDate.addingTimeInterval(-Session.tokenRefreshMargin) {
			await refreshAccessToken()
		}
	}

	/// Schedules a background task that automatically refreshes the access token before it expires.
	/// Call this after a successful login or on app startup.
	public func scheduleAccessTokenRefresh() {
		tokenRefreshTask?.cancel()
		let expirationDate = self.config.tokenExpirationDate
		let delay: TimeInterval
		if let expirationDate {
			// Refresh 5 minutes before expiration, minimum 30 seconds
			delay = max(expirationDate.timeIntervalSinceNow - Session.tokenRefreshMargin, 30)
		} else {
			// No expiration known — try refreshing in 10 minutes
			delay = 10 * 60
		}
		tokenRefreshTask = Task { [weak self] in
			do {
				try await Task.sleep(for: .seconds(delay))
			} catch {
				return // Task was cancelled
			}
			await self?.refreshAccessToken()
		}
	}
}

extension Session {
	public func logout() {
		tokenRefreshTask?.cancel()
		tokenRefreshTask = nil
		deletePersistentInformation()
		config = Config(accessToken: "", refreshToken: "", clientID: "", offlineAudioQuality: .hifi, urlType: .streaming)
	}
}
