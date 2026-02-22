//
//  Session.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public class Session {
	public var config: Config
	
	var countryCode: String?
	public var userId: Int?
	
	var sessionParameters: [String: String] {
		if countryCode == nil {
			return [:]
		} else {
			return ["countryCode": countryCode!,
					"limit": "999"]
		}
		
	}
	
	public var favorites: Favorites?
	public var helpers: Helpers!
	public var playlistEditing: PlaylistEditing!
	var tokenRefreshTask: Task<Void, Never>?
	
	public init(config: Config?) {
		if let config = config {
			self.config = config
		} else {
			if let config = Config.load() {
				self.config = config
			} else {
				self.config = Config(
					accessToken: "",
					refreshToken: "",
					clientID: "",
					offlineAudioQuality: .hifi,
					urlType: .streaming
				)
			}
		}
		helpers = Helpers(session: self)
		playlistEditing = PlaylistEditing(session: self)
	}
}
