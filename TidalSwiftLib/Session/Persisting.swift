//
//  Persisting.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

struct PersistentInformation {
	var sessionId: String
	var countryCode: String
	var userId: Int
}

extension Session {
	public func loadSession() -> Bool {
		let persistentInformationOptional: [String: String]? =
			UserDefaults.standard.dictionary(forKey: "Session Information") as? [String: String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Session", content: "Persistent Session Information doesn't exist")
			return false
		}
		
		countryCode = persistentInformation["countryCode"]
		userId = Int(persistentInformation["userId"]!)
		favorites = Favorites(session: self, userId: userId!)
		return true
	}
	
	public func saveSession() {
		guard let countryCode = countryCode,
			  let userId = userId else {
			displayError(title: "Couldn't save Session Information",
						 content: "Session Information wasn't set yet. You're probably not logged in.")
			return
		}
		
		let persistentInformation: [String: String] = ["countryCode": countryCode,
													   "userId": String(userId)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Session Information")
	}
	
	public func saveConfig() {
		let persistentInformation: [String: String?] = [
			"accessToken": config.accessToken,
			"refreshToken": config.refreshToken,
			"apiToken": config.apiToken,
			"clientId": config.clientId,
			"clientSecret": config.clientSecret,
			"offlineAudioQuality": config.offlineAudioQuality.rawValue,
			"urlType": config.urlType.rawValue,
			"apiLocation": config.apiLocation,
			"authLocation": config.authLocation,
			"imageLocation": config.imageLocation,
			"imageSize": String(config.imageSize)
		]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Config Information")
	}
	
	public func deletePersistentInformation() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}
}

extension Config {
	static func load() -> Config? {
		let persistentInformationOptional: [String: String]? =
			UserDefaults.standard.dictionary(forKey: "Config Information") as? [String: String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Config", content: "Persistent Config doesn't exist")
			return nil
		}
		
		guard let accessToken = persistentInformation["accessToken"],
			  let apiToken = persistentInformation["apiToken"],
			  let clientId = persistentInformation["clientId"],
			  let clientSecret = persistentInformation["clientSecret"],
			  let offlineAudioQualityString = persistentInformation["offlineAudioQuality"],
			  let offlineAudioQuality = AudioQuality(rawValue: offlineAudioQualityString),
			  let urlTypeString = persistentInformation["urlType"],
			  let urlType = AudioUrlType(rawValue: urlTypeString),
			  let apiLocation = persistentInformation["apiLocation"],
			  let authLocation = persistentInformation["authLocation"],
			  let imageLocation = persistentInformation["imageLocation"],
			  let imageSizeString = persistentInformation["imageSize"],
			  let imageSize = Int(imageSizeString)
		else {
			displayError(title: "Couldn't load Config", content: "Missing part of Persistent Config.")
			return nil
		}
		
		let refreshToken = persistentInformation["refreshToken"]
		
		return Config(accessToken: accessToken,
					  refreshToken: refreshToken,
					  apiToken: apiToken,
					  clientId: clientId,
					  clientSecret: clientSecret,
					  offlineAudioQuality: offlineAudioQuality,
					  urlType: urlType,
					  apiLocation: apiLocation,
					  authLocation: authLocation,
					  imageLocation: imageLocation,
					  imageSize: imageSize)
	}
}
