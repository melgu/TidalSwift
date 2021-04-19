//
//  Config.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public typealias Authorization = String

public class Config {
	var authorization: Authorization
	var apiToken: String
	var offlineAudioQuality: AudioQuality
	var apiLocation: String
	var imageLocation: String
	var imageSize: Int
	public var urlType: AudioUrlType
	
	public init(
		authorization: Authorization,
		apiToken: String? = nil,
		offlineAudioQuality: AudioQuality,
		urlType: AudioUrlType,
		apiLocation: String = "https://api.tidal.com/v1",
		imageLocation: String = "https://resources.tidal.com/images",
		imageSize: Int = 1280
	) {
		self.authorization = authorization
		
		if let token = apiToken {
			self.apiToken = token
		} else {
			self.apiToken = "_DSTon1kC8pABnTw" // Direct ALAC, 1080p Videos
		}
		
		self.offlineAudioQuality = offlineAudioQuality
		self.urlType = urlType
		
		self.apiLocation = apiLocation.replacingOccurrences(of: " ", with: "")
		if apiLocation.last == "/" {
			self.apiLocation = String(apiLocation.dropLast())
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
		
		guard let authorization = persistentInformation["authorization"],
			  let apiToken = persistentInformation["apiToken"],
			  let offlineAudioQualityString = persistentInformation["offlineAudioQuality"],
			  let offlineAudioQuality = AudioQuality(rawValue: offlineAudioQualityString),
			  let urlTypeString = persistentInformation["urlType"],
			  let urlType = AudioUrlType(rawValue: urlTypeString),
			  let apiLocation = persistentInformation["apiLocation"],
			  let imageLocation = persistentInformation["imageLocation"],
			  let imageSizeString = persistentInformation["imageSize"],
			  let imageSize = Int(imageSizeString)
		else {
			displayError(title: "Couldn't load Config", content: "Missing part of Persistent Config.")
			return nil
		}
		
		return Config(authorization: authorization,
					  apiToken: apiToken,
					  offlineAudioQuality: offlineAudioQuality,
					  urlType: urlType,
					  apiLocation: apiLocation,
					  imageLocation: imageLocation,
					  imageSize: imageSize)
	}
}
