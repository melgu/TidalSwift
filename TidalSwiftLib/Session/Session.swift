//
//  Session.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public class Session {
	var config: Config
	public var sessionConfig: Config { config }
	
	var sessionId: String?
	var countryCode: String?
	public var userId: Int?
	
	var sessionParameters: [String: String] {
		if sessionId == nil || countryCode == nil {
			return [:]
		} else {
			return ["sessionId": sessionId!,
					"countryCode": countryCode!,
					"limit": "999"]
		}
		
	}
	
	public var favorites: Favorites?
	public var helpers: Helpers!
	public var playlistEditing: PlaylistEditing!
	
	public init(config: Config?) {
		func loadConfig() -> Config? {
			let persistentInformationOptional: [String: String]? =
				UserDefaults.standard.dictionary(forKey: "Config Information") as? [String: String]
			
			guard let persistentInformation = persistentInformationOptional else {
				displayError(title: "Couldn't load Config", content: "Persistent Config doesn't exist")
				return nil
			}
			
			guard let qualityString = persistentInformation["quality"],
				let quality = AudioQuality(rawValue: qualityString),
				let username = persistentInformation["username"],
				let password = persistentInformation["password"],
				let urlTypeString = persistentInformation["urlType"],
				let urlType = AudioUrlType(rawValue: urlTypeString),
				let apiToken = persistentInformation["apiToken"],
				let apiLocation = persistentInformation["apiLocation"],
				let imageLocation = persistentInformation["imageLocation"],
				let imageSizeString = persistentInformation["imageSize"],
				let imageSize = Int(imageSizeString)
			else {
				displayError(title: "Couldn't load Config", content: "Missing part of Persistent Config.")
				return nil
			}
			
			return Config(quality: quality,
						  loginCredentials: LoginCredentials(username: username,
															 password: password),
						  urlType: urlType,
						  apiToken: apiToken,
						  apiLocation: apiLocation,
						  imageLocation: imageLocation,
						  imageSize: imageSize)
		}
		
		if let config = config {
			self.config = config
		} else {
			if let config = loadConfig() {
				self.config = config
			} else {
				self.config = Config(loginCredentials: LoginCredentials(username: "", password: ""), urlType: .offline)
			}
		}
		helpers = Helpers(session: self)
		playlistEditing = PlaylistEditing(session: self)
	}
}
