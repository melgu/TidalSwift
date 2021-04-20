//
//  Config.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public class Config {
	var accessToken: String
	var refreshToken: String?
	var apiToken: String
	var clientId: String // Needs to be from TV for device auth to work
	var clientSecret: String // Needs to be from TV for device auth to work
	var offlineAudioQuality: AudioQuality
	var apiLocation: String
	var authLocation: String
	var imageLocation: String
	var imageSize: Int
	public var urlType: AudioUrlType
	
	public init(
		accessToken: String,
		refreshToken: String?,
		apiToken: String? = nil,
		clientId: String = "aR7gUaTK1ihpXOEP",
		clientSecret: String = "eVWBEkuL2FCjxgjOkR3yK0RYZEbcrMXRc2l8fU3ZCdE",
		offlineAudioQuality: AudioQuality,
		urlType: AudioUrlType,
		apiLocation: String = "https://api.tidal.com/v1",
		authLocation: String = "https://auth.tidal.com/v1/oauth2",
		imageLocation: String = "https://resources.tidal.com/images",
		imageSize: Int = 1280
	) {
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		
		if let token = apiToken {
			self.apiToken = token
		} else {
			self.apiToken = "_DSTon1kC8pABnTw" // Direct ALAC, 1080p Videos
		}
		
		self.clientId = clientId
		self.clientSecret = clientSecret
		
		self.offlineAudioQuality = offlineAudioQuality
		self.urlType = urlType
		
		self.apiLocation = apiLocation.replacingOccurrences(of: " ", with: "")
		if apiLocation.last == "/" {
			self.apiLocation = String(apiLocation.dropLast())
		}
		
		self.authLocation = authLocation.replacingOccurrences(of: " ", with: "")
		if authLocation.last == "/" {
			self.authLocation = String(apiLocation.dropLast())
		}
		
		self.imageLocation = imageLocation.replacingOccurrences(of: " ", with: "")
		if imageLocation.last == "/" {
			self.imageLocation = String(imageLocation.dropLast())
		}
		
		self.imageSize = imageSize
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
			  let refreshToken = persistentInformation["refreshToken"],
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
