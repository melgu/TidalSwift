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
		
		authorization = persistentInformation["authorization"]
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
		
		let persistentInformation: [String: String] = ["authorization": authorization ?? "",
													   "countryCode": countryCode,
													   "userId": String(userId)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Session Information")
	}
	
	public func saveConfig() {
		let persistentInformation: [String: String] = ["quality": config.quality.rawValue,
													   "username": config.loginCredentials.username,
													   "password": config.loginCredentials.password,
													   "urlType": config.urlType.rawValue,
													   "apiToken": config.apiToken,
													   "apiLocation": config.apiLocation,
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
