//
//  Logic.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Cocoa

struct LoginInformation {
	var username: String
	var password: String
}

struct PersistentInformation {
	var sessionId: String
	var countryCode: String
	var userId: Int
}

enum Quality {
	case LOSSLESS
	case HIGH
	case LOW
}

enum Codec {
	case FLAC
	case ALAC
	case AAC
}

class Config {
	var quality: Quality
	var apiLocation: String // https://api.tidalhifi.com/v1/
	var apiToken: String
	
	init(quality: Quality = .LOSSLESS, apiLocation: String = "https://api.tidalhifi.com/v1/", apiToken: String? = nil) {
		self.quality = quality
		print(quality)
		self.apiLocation = apiLocation
		
		if apiToken == nil {
			if quality == .LOSSLESS {
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
	
	lazy var sessionParameters: [String: String] = {
		if sessionId == nil || countryCode == nil {
			return [:]
		} else {
			return ["sessionId": sessionId!,
					"countryCode": countryCode!,
					"limit": "999"]
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
		if user == nil || self.sessionId == nil  {
			return false
		}
		let url = URL(string: "\(config.apiLocation)users/\(self.user!.id)/subscription")!
		print(sessionParameters)
		return get(url: url, parameters: sessionParameters).ok
	}
	
	func getMediaUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality)"
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/streamUrl")!
		let response = get(url: url, parameters: parameters)
		
		var mediaUrlResponse: MediaUrlResponse
		do {
			mediaUrlResponse = try JSONDecoder().decode(MediaUrlResponse.self, from: response.content!)
		} catch {
			appDelegate.mainViewController?.errorDialog(title: "Login failed (JSON Parse Error)", text: "Couldn't Parse JSON Response: \(response.content!)")
			return nil
		}
		print("Track ID: \(mediaUrlResponse.trackId), Quality: \(mediaUrlResponse.soundQuality), Codec: \(mediaUrlResponse.codec)")
		return URL(string: mediaUrlResponse.url)
	}
	
//	func search(section: String, term: String) -> SearchResult {
//		var parameters = sessionParameters
//		parameters["query"] = term
//		parameters["limit"] = "50"
//		if ["artist", "album", "playlist", "track"].contains(section) {
//			let sectionPlural = section + "s"
//			let url = URL(string: "\(config.apiLocation)search/\(sectionPlural)")!
//			let result = mapRequest(url: url, parameters: parameters, ret: sectionPlural)
//
//		}
//	}
	
//	func mapRequest(url: URL, parameters: [String: String], ret: String) -> Any {
//		let obj = get(url: url, parameters: parameters)
//		var parse: Any
//		if ret.starts(with: "artist") {
//			parse =
//		}
//	}
//
//	func parseArtist(json) -> <#return type#> {
//		<#function body#>
//	}
	
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
