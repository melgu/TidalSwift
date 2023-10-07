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
	public func setAccessToken(_ accessToken: String, refreshToken: String?) async -> Bool {
		var token = accessToken
		if !token.hasPrefix("Bearer ") {
			token = "Bearer " + token
		}
		
		config.accessToken = token
		if let refreshToken = refreshToken {
			config.refreshToken = refreshToken
		}
		return await populateVariablesForAccessToken()
	}
	
	public func populateVariablesForAccessToken() async -> Bool {
		let url = URL(string: "\(AuthInformation.APILocation)/sessions")!
		do {
			let response: Sessions = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			self.countryCode = response.countryCode
			self.userId = response.userId
			self.favorites = Favorites(session: self, userId: response.userId)
			return true
		} catch {
			return false
		}
	}
}

extension Session {
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
		let parameters: [String: String] = ["client_id": AuthInformation.ClientID,
											"scope": "r_usr+w_usr+w_sub"]
		
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
		let parameters: [String: String] = ["client_id": AuthInformation.ClientID,
											"client_secret": AuthInformation.ClientSecret,
											"device_code": deviceCode.uuidString.lowercased(),
											"grant_type": "urn:ietf:params:oauth:grant-type:device_code",
											"scope": "r_usr+w_usr+w_sub"]
		
		Task {
			try await Task.sleep(for: .seconds(2))
			authorizationPoll(url: url, parameters: parameters, subject: subject)
		}
	}
	
	// TODO: Test this!
	private func authorizationPoll(url: URL, parameters: [String: String], subject: CurrentValueSubject<AuthorizationState, Never>) {
		Task {
			do {
				let response = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
				if let successResponse = try? JSONDecoder.custom.decode(TokenSuccessResponse.self, from: response.data) {
					if await setAccessToken(successResponse.accessToken, refreshToken: successResponse.refreshToken) {
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
		guard let refreshToken = config.refreshToken else {
			displayError(title: "Refresh Access Token failed (Token Error)", content: "Missing Refresh Token")
			return
		}
		let url = URL(string: "\(AuthInformation.AuthLocation)/token")!
		let parameters: [String: String] = ["client_id": AuthInformation.ClientID,
											"client_secret": AuthInformation.ClientSecret,
											"refresh_token": refreshToken,
											"grant_type": "refresh_token",
											"scope": "r_usr+w_usr+w_sub"]
		
		do {
			let response: TokenSuccessResponse = try await Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
			config.accessToken = response.accessToken
		} catch {
			displayError(title: "Refresh Access Token failed", content: "Error: \(error)")
		}
	}
}

extension Session {
	public func logout() {
		deletePersistentInformation()
		config = Config(accessToken: "", refreshToken: nil, offlineAudioQuality: .hifi, urlType: .streaming)
	}
}
