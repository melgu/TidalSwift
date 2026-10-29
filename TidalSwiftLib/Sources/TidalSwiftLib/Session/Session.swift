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
	/// Service name of the Keychain item holding the login
	let keychainService: String
	/// What the Keychain holds, to skip unchanged writes
	var savedCredentials: Credentials?
	
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
	var activeTokenRefresh: Task<Void, Error>?
	
	public init(config: Config?, keychainService: String = Bundle.main.bundleIdentifier ?? "TidalSwift") {
		self.keychainService = keychainService
		if let config = config {
			self.config = config
		} else {
			if let loaded = Config.load(keychainService: keychainService) {
				self.config = loaded.config
				savedCredentials = loaded.savedCredentials
			} else {
				self.config = Config(
					accessToken: "",
					refreshToken: "",
					clientID: ""
				)
			}
		}
		helpers = Helpers(session: self)
		playlistEditing = PlaylistEditing(session: self)
	}
}
