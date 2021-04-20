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
	public func populateVariablesForAuthorization() -> Bool {
		let url = URL(string: "\(config.apiLocation)/sessions")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
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
	}
	
	public func startAuthorization() -> CurrentValueSubject<AuthorizationState, Never> {
		let subject = CurrentValueSubject<AuthorizationState, Never>(.waiting)
		
		let url = URL(string: "https://auth.tidal.com/v1/oauth2/device_authorization")!
		let parameters: [String: String] = ["client_id": "aR7gUaTK1ihpXOEP", "scope": "r_usr+w_usr+w_sub"]
		Network.asyncPost(url: url, parameters: parameters, authorization: nil, xTidalToken: nil) { [weak self] response in
			guard let content = response.content else {
				displayError(title: "Device Authorization Request failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
				return
			}
			
			var optionalDeviceAuth: DeviceAuthorizationResponse?
			do {
				optionalDeviceAuth = try customJSONDecoder.decode(DeviceAuthorizationResponse.self, from: content)
			} catch {
				displayError(title: "Device Authorization Request failed (JSON Parse Error)", content: "\(error)")
			}
			
			guard let deviceAuthResponse = optionalDeviceAuth else {
				subject.send(.failure(AuthorizationError.deviceAuthorizationFailed))
				return
			}
			
			let expiration = Date().addingTimeInterval(TimeInterval(deviceAuthResponse.expiresIn))
			subject.send(.pending(loginUrl: deviceAuthResponse.verificationUriComplete, expiration: expiration))
			
			self?.startAuthorizationPolling(subject: subject)
		}
		
		return subject
	}
	
	private func startAuthorizationPolling(subject: CurrentValueSubject<AuthorizationState, Never>) {
		// TODO: 2 sec polling
	}
}
