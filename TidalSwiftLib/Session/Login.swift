//
//  Login.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func login() -> Bool {
		let url = URL(string: "\(config.apiLocation)/login/username")!
		let parameters: [String: String] = [
			"token": config.apiToken,
			"username": config.loginCredentials.username,
			"password": config.loginCredentials.password
		]
		let response = Network.post(url: url, parameters: parameters, authorization: authorization, xTidalToken: config.apiToken)
		if !response.ok {
			if response.statusCode == 401 { // Wrong Username / Password
				displayError(title: "Wrong username or password",
							 content: "Username, password, token, or API Location is wrong.")
				return false
			} else {
				displayError(title: "Login failed (HTTP Error)",
							 content: "Status Code: \(response.statusCode ?? -1)\nPlease report this error to the developer.")
				return false
			}
		}
		
		guard let content = response.content else {
			displayError(title: "Login failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var loginResponse: LoginResponse
		do {
			loginResponse = try JSONDecoder().decode(LoginResponse.self, from: content)
		} catch {
			displayError(title: "Login failed (JSON Parse Error)", content: "\(error)")
			return false
		}
		
//		sessionId = loginResponse.sessionId
		countryCode = loginResponse.countryCode
		userId = loginResponse.userId
		favorites = Favorites(session: self, userId: userId!)
		return true
	}
	
	public func setAuthorization(authorization: Authorization, countryCode: String, userId: Int) {
		self.authorization = authorization
		self.countryCode = countryCode
		self.userId = userId
		self.favorites = Favorites(session: self, userId: userId)
	}
	
	public func checkLogin() -> Bool {
		guard let userId = userId, authorization != nil else {
			return false
		}
		
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/subscription")!
//		print(sessionParameters)
		return Network.get(url: url, parameters: sessionParameters, authorization: authorization, xTidalToken: config.apiToken).ok
	}
}
