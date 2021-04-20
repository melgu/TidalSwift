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
	
	public init(config: Config?) {
		if let config = config {
			self.config = config
		} else {
			if let config = Config.load() {
				self.config = config
			} else {
				self.config = Config(accessToken: "", refreshToken: nil, offlineAudioQuality: .hifi, urlType: .offline)
			}
		}
		helpers = Helpers(session: self)
		playlistEditing = PlaylistEditing(session: self)
	}
}
