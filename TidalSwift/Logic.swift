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
	var imageUrl: URL
	var imageSize: Int
	
	init(quality: Quality = .LOSSLESS,
		 apiLocation: String = "https://api.tidalhifi.com/v1/",
		 apiToken: String? = nil,
		 imageUrl: URL = URL(string: "http://images.osl.wimpmusic.com/im/im")!,
		 imageSize: Int = 1280) {
		self.quality = quality
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
		
		self.imageUrl = imageUrl
		self.imageSize = imageSize
	}
}

class Session {
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
			displayError(title: "Login failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var loginResponse: LoginResponse
		do {
			loginResponse = try JSONDecoder().decode(LoginResponse.self, from: response.content!)
		} catch {
			displayError(title: "Login failed (JSON Parse Error)", content: "\(error)")
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
	
	func getSubscriptionInfo() -> SubscriptionResponse? {
		if user == nil  {
			return nil
		}
		
		let url = URL(string: "\(config.apiLocation)users/\(self.user!.id)/subscription")!
		let response = get(url: url, parameters: sessionParameters)
		
		var searchResultResponse: SubscriptionResponse?
		do {
			searchResultResponse = try customJSONDecoder().decode(SubscriptionResponse.self, from: response.content!)
		} catch {
			displayError(title: "Subscription Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	func getMediaUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality)"
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/streamUrl")!
		let response = get(url: url, parameters: parameters)
		
		var mediaUrlResponse: MediaUrlResponse?
		do {
			mediaUrlResponse = try JSONDecoder().decode(MediaUrlResponse.self, from: response.content!)
		} catch {
			displayError(title: "Couldn't get media URL (JSON Parse Error)", content: "\(error)")
		}
//		print("Track ID: \(mediaUrlResponse.trackId), Quality: \(mediaUrlResponse.soundQuality), Codec: \(mediaUrlResponse.codec)")
		
		return mediaUrlResponse?.url
	}
	
	func search(for term: String, limit: Int = 50) -> SearchResultResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		
		let url = URL(string: "\(config.apiLocation)search/")!
		let response = get(url: url, parameters: parameters)
//		print(String(data: response.content!, encoding: String.Encoding.utf8))
		
		var searchResultResponse: SearchResultResponse?
		do {
			searchResultResponse = try customJSONDecoder().decode(SearchResultResponse.self, from: response.content!)
		} catch {
			displayError(title: "Search failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
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

func displayError(title: String, content: String) {
	let appDelegate = NSApplication.shared.delegate as! AppDelegate
	
	print("Error info: \(content)")
	appDelegate.mainViewController?.errorDialog(title: title, text: content)
}
