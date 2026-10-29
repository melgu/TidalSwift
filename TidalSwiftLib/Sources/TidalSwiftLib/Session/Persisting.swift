//
//  Persisting.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import OSLog

private let logger = Logger(category: "Persisting")

private struct PersistentInformation {
	var sessionId: String
	var countryCode: String
	var userId: Int
}

extension Session {
	public func loadSession() -> Bool {
		// Without credentials, e.g. after a failed Keychain read, every request would fail while appearing logged in
		guard !config.refreshToken.isEmpty else {
			displayError(title: "Couldn't load Session", content: "Login credentials don't exist")
			return false
		}
		
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
		let credentials = Credentials(config: config)
		// Never write empty credentials, which would replace a login that just couldn't be read
		if credentials != savedCredentials && !credentials.refreshToken.isEmpty {
			do {
				try Keychain.save(JSONEncoder().encode(credentials), service: keychainService, account: credentialsAccount)
				savedCredentials = credentials
			} catch {
				displayError(title: "Couldn't save Login", content: "Couldn't write to Keychain: \(error)")
			}
		}
		
		var persistentInformation: [String: String] = [
			"apiToken": config.apiToken,
			"offlineAudioQuality": config.offlineAudioQuality.rawValue,
			"imageSize": String(config.imageSize)
		]
		// Keep credentials that couldn't be moved to the Keychain yet
		if savedCredentials == nil,
		   let previousInformation = UserDefaults.standard.dictionary(forKey: "Config Information") as? [String: String] {
			for key in legacyCredentialKeys {
				persistentInformation[key] = previousInformation[key]
			}
		}
		UserDefaults.standard.set(persistentInformation, forKey: "Config Information")
	}
	
	public func deletePersistentInformation() {
		do {
			try Keychain.delete(service: keychainService, account: credentialsAccount)
		} catch {
			displayError(title: "Couldn't delete Login", content: "Couldn't remove from Keychain: \(error)")
		}
		savedCredentials = nil
		
		if let domain = Bundle.main.bundleIdentifier {
			UserDefaults.standard.removePersistentDomain(forName: domain)
		} else {
			// Command line tools have no bundle identifier
			UserDefaults.standard.removeObject(forKey: "Session Information")
			UserDefaults.standard.removeObject(forKey: "Config Information")
		}
	}
}

/// Login secrets, stored in the Keychain instead of UserDefaults
struct Credentials: Codable, Equatable {
	var accessToken: String
	var refreshToken: String
	var clientID: String
	var tokenExpirationDate: Date?
}

extension Credentials {
	init(config: Config) {
		self.init(
			accessToken: config.accessToken,
			refreshToken: config.refreshToken,
			clientID: config.clientID,
			tokenExpirationDate: config.tokenExpirationDate
		)
	}
}

private let credentialsAccount = "Credentials"

/// Keys older versions stored the credentials under in UserDefaults
private let legacyCredentialKeys = ["accessToken", "refreshToken", "clientID", "tokenExpirationDate"]

extension Config {
	/// `savedCredentials` is nil if the credentials couldn't be moved to the Keychain
	static func load(keychainService: String) -> (config: Config, savedCredentials: Credentials?)? {
		let persistentInformationOptional: [String: String]? =
			UserDefaults.standard.dictionary(forKey: "Config Information") as? [String: String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Config", content: "Persistent Config doesn't exist")
			return nil
		}
		
		guard let apiToken = persistentInformation["apiToken"],
			  let offlineAudioQualityString = persistentInformation["offlineAudioQuality"],
			  let offlineAudioQuality = AudioQuality(rawValue: offlineAudioQualityString),
			  let imageSizeString = persistentInformation["imageSize"],
			  let imageSize = Int(imageSizeString)
		else {
			displayError(title: "Couldn't load Config", content: "Missing part of Persistent Config.")
			return nil
		}
		
		guard let loaded = loadCredentials(keychainService: keychainService, persistentInformation: persistentInformation) else {
			return nil
		}
		let credentials = loaded.credentials
		
		let config = Config(
			accessToken: credentials.accessToken,
			refreshToken: credentials.refreshToken,
			clientID: credentials.clientID,
			apiToken: apiToken,
			offlineAudioQuality: offlineAudioQuality,
			imageSize: imageSize,
			tokenExpirationDate: credentials.tokenExpirationDate
		)
		return (config, loaded.isInKeychain ? credentials : nil)
	}
	
	private static func loadCredentials(keychainService: String, persistentInformation: [String: String]) -> (credentials: Credentials, isInKeychain: Bool)? {
		do {
			if let data = try Keychain.load(service: keychainService, account: credentialsAccount) {
				return (try JSONDecoder().decode(Credentials.self, from: data), true)
			}
		} catch {
			displayError(title: "Couldn't load Login", content: "Couldn't read from Keychain: \(error)")
			return nil
		}
		
		guard let credentials = legacyCredentials(from: persistentInformation) else {
			displayError(title: "Couldn't load Login", content: "Login doesn't exist in Keychain")
			return nil
		}
		
		// Move the credentials over from UserDefaults, but keep them there if that fails
		do {
			try Keychain.save(JSONEncoder().encode(credentials), service: keychainService, account: credentialsAccount)
			var remainingInformation = persistentInformation
			for key in legacyCredentialKeys {
				remainingInformation[key] = nil
			}
			UserDefaults.standard.set(remainingInformation, forKey: "Config Information")
			return (credentials, true)
		} catch {
			logger.error("Couldn't move login to Keychain: \(String(describing: error))")
			return (credentials, false)
		}
	}
	
	private static func legacyCredentials(from persistentInformation: [String: String]) -> Credentials? {
		guard let accessToken = persistentInformation["accessToken"],
			  let refreshToken = persistentInformation["refreshToken"]
		else {
			return nil
		}
		
		var tokenExpirationDate: Date?
		if let expirationString = persistentInformation["tokenExpirationDate"],
		   let expirationInterval = Double(expirationString) {
			tokenExpirationDate = Date(timeIntervalSince1970: expirationInterval)
		}
		
		return Credentials(
			accessToken: accessToken,
			refreshToken: refreshToken,
			clientID: persistentInformation["clientID"] ?? AuthInformation.OAuthClientID,
			tokenExpirationDate: tokenExpirationDate
		)
	}
}
