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
	public func setAccessToken(_ accessToken: String, refreshToken: String?) -> Bool {
		var token = accessToken
		if !token.hasPrefix("Bearer ") {
			token = "Bearer " + token
		}
		
		config.accessToken = token
		if let refreshToken = refreshToken {
			config.refreshToken = refreshToken
		}
		return populateVariablesForAccessToken()
	}
	
	public func populateVariablesForAccessToken() -> Bool {
		let url = URL(string: "\(config.apiLocation)/sessions")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Sessions Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var sessions: Sessions?
		do {
			sessions = try customJSONDecoder.decode(Sessions.self, from: content)
		} catch {
			displayError(title: "Sessions Info failed (JSON Parse Error)", content: "\(error)")
			return false
		}
		
		if let sessions = sessions {
			self.countryCode = sessions.countryCode
			self.userId = sessions.userId
			self.favorites = Favorites(session: self, userId: sessions.userId)
			return true
		}
			
		return false
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
		
		let url = URL(string: "\(config.authLocation)/device_authorization")!
		let parameters: [String: String] = ["client_id": config.clientId,
											"scope": "r_usr+w_usr+w_sub"]
		
		Network.asyncPost(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil) { [weak self] response in
			guard let content = response.content else {
				displayError(title: "Device Authorization Request failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
				return
			}
			
			var optionalResponse: DeviceAuthorizationResponse?
			do {
				optionalResponse = try customJSONDecoder.decode(DeviceAuthorizationResponse.self, from: content)
			} catch {
				displayError(title: "Device Authorization Request failed (JSON Parse Error)", content: "\(error)")
			}
			
			guard let deviceAuthResponse = optionalResponse else {
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
				return
			}
			
			let expiration = Date().addingTimeInterval(TimeInterval(deviceAuthResponse.expiresIn))
			let loginUrlString = "https://\(deviceAuthResponse.verificationUriComplete.absoluteString)"
			let loginUrl = URL(string: loginUrlString)!
			subject.send(.pending(loginUrl: loginUrl, expiration: expiration))
			
			self?.startAuthorizationPolling(deviceCode: deviceAuthResponse.deviceCode, subject: subject)
		}
		
		return subject
	}
	
	private func startAuthorizationPolling(deviceCode: UUID, subject: CurrentValueSubject<AuthorizationState, Never>) {
		let url = URL(string: "\(config.authLocation)/token")!
		let parameters: [String: String] = ["client_id": config.clientId,
											"client_secret": config.clientSecret,
											"device_code": deviceCode.uuidString.lowercased(),
											"grant_type": "urn:ietf:params:oauth:grant-type:device_code",
											"scope": "r_usr+w_usr+w_sub"]
		
		DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
			self?.authorizationPoll(url: url, parameters: parameters, subject: subject)
		}
	}
	
	private func authorizationPoll(url: URL, parameters: [String: String], subject: CurrentValueSubject<AuthorizationState, Never>) {
		Network.asyncPost(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil) { [weak self] response in
			guard let content = response.content else {
				displayError(title: "Authorization Polling failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
				return
			}
			
			if response.ok {
				var optionalResponse: TokenSuccessResponse?
				do {
					optionalResponse = try customJSONDecoder.decode(TokenSuccessResponse.self, from: content)
				} catch {
					displayError(title: "Authorization Polling failed (JSON Parse Error)", content: "\(error)")
				}
				
				guard let tokenResponse = optionalResponse else {
					subject.send(.failure(AuthorizationError.pollingFailed))
					return
				}
				
				if self?.setAccessToken(tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken) == true {
					subject.send(.success)
				} else {
					subject.send(.failure(AuthorizationError.unknown))
				}
				return
			} else {
				var optionalResponse: TokenErrorResponse?
				do {
					optionalResponse = try customJSONDecoder.decode(TokenErrorResponse.self, from: content)
				} catch {
					displayError(title: "Authorization Polling failed (JSON Parse Error)", content: "\(error)")
				}
				
				guard let errorResponse = optionalResponse else {
					subject.send(.failure(AuthorizationError.pollingFailed))
					return
				}
				
				print(errorResponse)
				
				switch errorResponse.error {
				case "authorization_pending":
					print("Auth pending")
					DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
						self?.authorizationPoll(url: url, parameters: parameters, subject: subject)
					}
				case "expired_token":
					print("Expired token")
					subject.send(.failure(AuthorizationError.expiredToken))
				default:
					print("Polling failed")
					subject.send(.failure(AuthorizationError.pollingFailed))
				}
			}
		}
	}
	
	public func refreshAccessToken() {
		guard let refreshToken = config.refreshToken else {
			displayError(title: "Refresh Access Token failed (Token Error)", content: "Missing Refresh Token")
			return
		}
		let url = URL(string: "\(config.authLocation)/token")!
		let parameters: [String: String] = ["client_id": config.clientId,
											"client_secret": config.clientSecret,
											"refresh_token": refreshToken,
											"grant_type": "refresh_token",
											"scope": "r_usr+w_usr+w_sub"]
		
		let response = Network.post(url: url, parameters: parameters, accessToken: nil, xTidalToken: nil)
		
		guard let content = response.content, response.ok else {
			displayError(title: "Refresh Access Token failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return
		}
		
		var optionalResponse: TokenSuccessResponse?
		do {
			optionalResponse = try customJSONDecoder.decode(TokenSuccessResponse.self, from: content)
		} catch {
			displayError(title: "Refresh Access Token failed (JSON Parse Error)", content: "\(error)")
		}
		
		guard let tokenResponse = optionalResponse else {
			return
		}
		
		config.accessToken = tokenResponse.accessToken
	}
}

extension Session {
	public func logout() {
		deletePersistentInformation()
		config = Config(accessToken: "", refreshToken: nil, offlineAudioQuality: .hifi, urlType: .streaming)
	}
}
