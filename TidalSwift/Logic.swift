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
	var countryCode: String?
	var user: User?
	
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
	
	func loadSession() {
		let persistentInformationOptional: [String: String]? = UserDefaults.standard.dictionary(forKey: "Session Information") as? [String : String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Session", content: "Persistent Session Information doesn't exist")
			return
		}
		
		self.sessionId = persistentInformation["sessionId"]
		self.countryCode = persistentInformation["countryCode"]
		self.user = User(session: self, id: Int(persistentInformation["userId"]!)!)
	}
	
	func saveSession() {
		guard let sessionId = sessionId, let countryCode = countryCode, let userId = user?.id else {
			displayError(title: "Couldn't save Session Information", content: "Session Information wasn't set yet.")
			return
		}
		
		let persistentInformation: [String: String] = ["sessionId": sessionId,
													   "countryCode": countryCode,
													   "userId": String(userId)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Session Information")
	}
	
	func loadLoginInformation() -> LoginInformation? {
		let persistentInformationOptional: [String: String]? = UserDefaults.standard.dictionary(forKey: "Login Information") as? [String : String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Login Information", content: "Persistent Login Information doesn't exist")
			return nil
		}
		
		return LoginInformation(username: persistentInformation["username"]!, password: persistentInformation["password"]!)
	}
	
	func saveLoginInformation(loginInformation: LoginInformation) {
		let persistentInformation = ["username": loginInformation.username,
									 "password": loginInformation.password]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Login Information")
	}
	
	func loadConfig() -> Config? {
		let persistentInformationOptional: [String: String]? = UserDefaults.standard.dictionary(forKey: "Config Information") as? [String : String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Config", content: "Persistent Config doesn't exist")
			return nil
		}
		
		var quality: Quality?
		switch persistentInformation["quality"] {
		case "LOSSLESS":
			quality = .LOSSLESS
		case "HIGH":
			quality = .HIGH
		case "LOW":
			quality = .LOW
		default:
			quality = .LOSSLESS
		}

		return Config(quality: quality!,
					  apiLocation: persistentInformation["apiLocation"]!,
					  apiToken: persistentInformation["apiToken"],
					  imageUrl: URL(string: persistentInformation["imageUrl"]!)!,
					  imageSize: Int(persistentInformation["imageSize"]!)!)
	}
	
	func saveConfig() {
		let persistentInformation: [String: String] = ["quality": "\(config.quality)",
													   "apiLocation": config.apiLocation,
													   "apiToken": config.apiToken,
													   "imageUrl": config.imageUrl.absoluteString,
													   "imageSize": String(config.imageSize)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Config Information")
	}
	
	func deletePersistantInformation() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}

	func readDemoLoginInformation() -> LoginInformation {
		let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
		var content = ""
		do {
			content = try String(contentsOfFile: fileLocation)
//			print(content)
		} catch {
			displayError(title: "Couldn't read Demo Login", content: "\(error)")
		}

		let lines: [String] = content.components(separatedBy: "\n")
		return LoginInformation(username: lines[0], password: lines[1])
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
//		print("Logged in as User: \(user!.id)")
//		print("Session ID: \(sessionId!)")
//		print("Country Code: \(countryCode!)")
		return true
	}
	
	func checkLogin() -> Bool {
		if user == nil || self.sessionId == nil  {
			return false
		}
		let url = URL(string: "\(config.apiLocation)users/\(self.user!.id)/subscription")!
//		print(sessionParameters)
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
	
	func search(for term: String, limit: Int = 50, offset: Int = 0) -> SearchResultResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit) // Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300. Can go higher using offset.
		parameters["offset"] = String(offset)
		
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
