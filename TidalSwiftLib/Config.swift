//
//  Config.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public struct LoginCredentials {
	var username: String
	var password: String
	
	public init(username: String, password: String) {
		self.username = username
		self.password = password
	}
}

public class Config {
	public var quality: AudioQuality
	var apiLocation: String
	var apiToken: String
	var imageLocation: String
	var imageSize: Int
	var loginCredentials: LoginCredentials
	public var urlType: AudioUrlType
	
	public init(quality: AudioQuality = .hifi,
		 loginCredentials: LoginCredentials,
		 urlType: AudioUrlType,
		 apiToken: String? = nil,
		 apiLocation: String = "https://api.tidal.com/v1",
		 imageLocation: String = "https://resources.tidal.com/images",
		 imageSize: Int = 1280) {
		self.quality = quality
		self.loginCredentials = loginCredentials
		self.urlType = urlType
		
		if let token = apiToken {
			self.apiToken = token
		} else {
			self.apiToken = "_DSTon1kC8pABnTw" // Direct ALAC, 1080p Videos
		}
		
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
