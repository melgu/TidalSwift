//
//  Config.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

enum AuthInformation {
    static let OAuthClientID = "4ywnjRfroi84hz7i"
    static let OAuthClientSecret = "7cNdrLt3NIQg0CHEpMDjcbV38XlwVdstczHqf59QiI0="
	static let scope = "r_usr+w_usr"
    static let APILocation = "https://api.tidal.com/v1"
    static let AuthLocation = "https://auth.tidal.com/v1/oauth2"
    static let ImageLocation = "https://resources.tidal.com/images"
}

public class Config {
	var accessToken: String
	var refreshToken: String
	var clientID: String
	var apiToken: String
	var offlineAudioQuality: AudioQuality
	var imageSize: Int
	public var urlType: AudioUrlType
	var tokenExpirationDate: Date?
	
	public init(
		accessToken: String,
		refreshToken: String,
		clientID: String,
		apiToken: String? = nil,
		offlineAudioQuality: AudioQuality,
		urlType: AudioUrlType,
		imageLocation: String = "",
		imageSize: Int = 1280,
		tokenExpirationDate: Date? = nil
	) {
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		self.clientID = clientID
		
		if let token = apiToken {
			self.apiToken = token
		} else {
			self.apiToken = "_DSTon1kC8pABnTw" // Direct ALAC, 1080p Videos
		}
		
		self.offlineAudioQuality = offlineAudioQuality
		self.urlType = urlType
		
		
		self.imageSize = imageSize
		self.tokenExpirationDate = tokenExpirationDate
	}
}
