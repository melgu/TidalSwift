//
//  Logic.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Cocoa

enum Quality {
	case lossless
	case high
	case low
}

struct LoginResponse: Decodable {
	let userId: Int
	let sessionId: String
	let countryCode: String
	
	init(userId: Int, sessionId: String, countryCode: String) {
		self.userId = userId
		self.sessionId = sessionId
		self.countryCode = countryCode
	}
	
	enum CodingKeys: String, CodingKey {
		case userId, sessionId, countryCode
	}
}

class Config {
	var quality: Quality
	var apiLocation: String // https://api.tidalhifi.com/v1/
	var apiToken: String
	
	init(quality: Quality = .lossless, apiLocation: String = "https://api.tidalhifi.com/v1/", apiToken: String? = nil) {
		self.quality = quality
		self.apiLocation = apiLocation
		
		if apiToken == nil {
			if quality == .lossless {
				self.apiToken = "P5Xbeo5LFvESeDy6"
			} else {
				self.apiToken = "wdgaB1CilGA-S_s2"
			}
		} else {
			self.apiToken = apiToken!
		}
	}
}

class Session {
	let appDelegate = NSApplication.shared.delegate as! AppDelegate
	
	var config: Config
	
	var sessionId: String?
	var user: User?
	var countryCode: String?
	
	lazy var sessionParameter: [String: String] = {
		if sessionId == nil {
			return [:]
		} else {
			return ["sessionId": sessionId!]
		}
		
	}()
	
	init(config: Config) {
		self.config = config
	}
	
	func loadSession(userId: Int, sessionId: String, countryCode: String) {
		self.user = User(session: self, id: userId)
		self.sessionId = sessionId
		self.countryCode = countryCode
	}
	
	func login(username: String, password: String) -> Bool {
		let url = URL(string: config.apiLocation + "login/username")!
		let parameters: [String: String] = [
			"token": config.apiToken,
			"username": username,
			"password": password
		]
		let response = post(url: url, parameters: parameters)
		if !response.ok {
			appDelegate.mainViewController?.errorDialog(title: "Login failed (HTTP Error)", text: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var loginResponse: LoginResponse
		do {
			loginResponse = try JSONDecoder().decode(LoginResponse.self, from: response.content!)
		} catch {
			appDelegate.mainViewController?.errorDialog(title: "Login failed (JSON Parse Error)", text: "Couldn't Parse JSON Response: \(response.content!)")
			return false
		}
		
		sessionId = loginResponse.sessionId
		countryCode = loginResponse.countryCode
		user = User(session: self, id: loginResponse.userId)
		print("Logged in as User: \(user!.id)")
		print("Session ID: \(sessionId!)")
		print("Country Code: \(countryCode!)")
		return true
	}
	
	func checkLogin() -> Bool {
		// TODO:
		if user == nil || self.sessionId == nil  {
			return false
		}
		let url = URL(string: "\(config.apiLocation)users/\(self.user!.id)/subscription")!
		print(sessionParameter)
		return get(url: url, parameters: sessionParameter).ok
	}
}

class Favorites {
	let session: Session
	let baseUrl: String
	
	init(session: Session, userId: Int) {
		self.session = session
		baseUrl = "users/\(userId)/favorites"
	}
}

class User {
	let session: Session
	let id: Int
	let favorites: Favorites
	
	init(session: Session, id: Int) {
		self.session = session
		self.id = id
		self.favorites = Favorites(session: session, userId: id)
	}
	
}
