//
//  Logic.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Cocoa

struct LoginInformation {
	var username: String
	var password: String
}

struct PersistentInformation {
	var sessionId: String
	var countryCode: String
	var userId: Int
}

enum Quality {
	case LOSSLESS
	case HIGH
	case LOW
}

enum Codec {
	case FLAC
	case ALAC
	case AAC
}

class Config {
	var quality: Quality
	var apiLocation: String
	var apiToken: String
	var imageUrl: String
	var imageSize: Int
	var loginInformation: LoginInformation
	
	init(quality: Quality = .LOSSLESS,
		 apiLocation: String = "https://api.tidalhifi.com/v1/",
		 apiToken: String? = nil,
		 imageUrl: String = "http://images.osl.wimpmusic.com/im/im/",
		 imageSize: Int = 1280,
		 loginInformation: LoginInformation) {
		self.quality = quality
		self.apiLocation = apiLocation
		
		if apiToken == nil {
			if quality == .LOSSLESS {
				self.apiToken = "P5Xbeo5LFvESeDy6"
			} else {
				self.apiToken = "wdgaB1CilGA-S_s2"
			}
		} else {
			self.apiToken = apiToken!
		}
		
		self.imageUrl = imageUrl
		self.imageSize = imageSize
		self.loginInformation = loginInformation
	}
}

class Session {
	var config: Config
	
	var sessionId: String?
	var countryCode: String?
	var userId: Int?
	
	lazy var sessionParameters: [String: String] = {
		if sessionId == nil || countryCode == nil {
			return [:]
		} else {
			return ["sessionId": sessionId!,
					"countryCode": countryCode!,
					"limit": "999"]
		}
		
	}()
	
	init(config: Config?) {
		func loadConfig() -> Config? {
			let persistentInformationOptional: [String: String]? =
				UserDefaults.standard.dictionary(forKey: "Config Information") as? [String: String]
			
			guard let persistentInformation = persistentInformationOptional else {
				displayError(title: "Couldn't load Config", content: "Persistent Config doesn't exist")
				return nil
			}
			
			var quality: Quality?
			switch persistentInformation["quality"] {
			case "LOSSLESS":
				quality = .LOSSLESS
			case "HIGH":
				quality = .HIGH
			case "LOW":
				quality = .LOW
			default:
				quality = .LOSSLESS
			}
			
			return Config(quality: quality!,
						  apiLocation: persistentInformation["apiLocation"]!,
						  apiToken: persistentInformation["apiToken"]!,
						  imageUrl: persistentInformation["imageUrl"]!,
						  imageSize: Int(persistentInformation["imageSize"]!)!,
						  loginInformation: LoginInformation(username: persistentInformation["username"]!,
															 password: persistentInformation["password"]!))
		}
		
		if let config = config {
			self.config = config
		} else {
			self.config = loadConfig()!
		}
		
	}
	
	func loadSession() {
		let persistentInformationOptional: [String: String]? =
			UserDefaults.standard.dictionary(forKey: "Session Information") as? [String: String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Session", content: "Persistent Session Information doesn't exist")
			return
		}
		
		self.sessionId = persistentInformation["sessionId"]
		self.countryCode = persistentInformation["countryCode"]
		self.userId = Int(persistentInformation["userId"]!)
	}
	
	func saveSession() {
		guard let sessionId = sessionId, let countryCode = countryCode, let userId = userId else {
			displayError(title: "Couldn't save Session Information",
						 content: "Session Information wasn't set yet. You're probably not logged in.")
			return
		}
		
		let persistentInformation: [String: String] = ["sessionId": sessionId,
													   "countryCode": countryCode,
													   "userId": String(userId)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Session Information")
	}
	
	func saveConfig() {
		let persistentInformation: [String: String] = ["quality": "\(config.quality)",
													   "apiLocation": config.apiLocation,
													   "apiToken": config.apiToken,
													   "imageUrl": config.imageUrl,
													   "imageSize": String(config.imageSize),
													   "username": config.loginInformation.username,
													   "password": config.loginInformation.password]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Config Information")
	}
	
	func deletePersistantInformation() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}
	
	func login() -> Bool {
		let url = URL(string: config.apiLocation + "login/username")!
		let parameters: [String: String] = [
			"token": config.apiToken,
			"username": config.loginInformation.username,
			"password": config.loginInformation.password
		]
		let response = post(url: url, parameters: parameters)
		if !response.ok {
			if response.statusCode == 401 { // Wrong Username / Password
				displayError(title: "Wrong username or password",
							 content: "The username and password combination you entered is wrong.")
				return false
			} else {
				displayError(title: "Login failed (HTTP Error)",
							 content: "Status Code: \(response.statusCode ?? -1)\nPlease report this error to the developer.")
				return false
			}
		}
		
		var loginResponse: LoginResponse
		do {
			loginResponse = try JSONDecoder().decode(LoginResponse.self, from: response.content!)
		} catch {
			displayError(title: "Login failed (JSON Parse Error)", content: "\(error)")
			return false
		}
		
		sessionId = loginResponse.sessionId
		countryCode = loginResponse.countryCode
		userId = loginResponse.userId
//		print("Logged in as User: \(user!.id)")
//		print("Session ID: \(sessionId!)")
//		print("Country Code: \(countryCode!)")
		return true
	}
	
	func checkLogin() -> Bool {
		guard let userId = userId, sessionId != nil else {
			return false
		}
		
		let url = URL(string: "\(config.apiLocation)users/\(userId)/subscription")!
//		print(sessionParameters)
		return get(url: url, parameters: sessionParameters).ok
	}
	
	func getSubscriptionInfo() -> SubscriptionResponse? {
		guard let userId = userId else {
			return nil
		}
		
		let url = URL(string: "\(config.apiLocation)users/\(userId)/subscription")!
		let response = get(url: url, parameters: sessionParameters)
		
		var searchResultResponse: SubscriptionResponse?
		do {
			searchResultResponse = try customJSONDecoder().decode(SubscriptionResponse.self, from: response.content!)
		} catch {
			displayError(title: "Subscription Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	func getMediaUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality)"
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/streamUrl")!
		let response = get(url: url, parameters: parameters)
		
		var mediaUrlResponse: MediaUrlResponse?
		do {
			mediaUrlResponse = try JSONDecoder().decode(MediaUrlResponse.self, from: response.content!)
		} catch {
			displayError(title: "Couldn't get media URL (JSON Parse Error)", content: "\(error)")
		}
		print("""
			Track ID: \(mediaUrlResponse?.trackId ?? -1),
			Quality: \(mediaUrlResponse?.soundQuality ?? ""),
			Codec: \(mediaUrlResponse?.codec ?? "")
			""")
		
		return mediaUrlResponse?.url
	}
	
	func search(for term: String, limit: Int = 50, offset: Int = 0) -> SearchResultResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		// Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300.
		// Can potentially go higher using offset.
		
		let url = URL(string: "\(config.apiLocation)search/")!
		let response = get(url: url, parameters: parameters)
//		print(String(data: response.content!, encoding: String.Encoding.utf8))
		
		var searchResultResponse: SearchResultResponse?
		do {
			searchResultResponse = try customJSONDecoder().decode(SearchResultResponse.self, from: response.content!)
		} catch {
			displayError(title: "Search failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	func getPlaylist(playlistId: String) -> SearchResultPlaylistResponse? {
		let url = URL(string: "\(config.apiLocation)playlists/\(playlistId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		var playlistResponse: SearchResultPlaylistResponse?
		do {
			playlistResponse = try customJSONDecoder().decode(SearchResultPlaylistResponse.self, from: response.content!)
		} catch {
			displayError(title: "Playlist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistResponse
	}
	
	func getPlaylistTracks(playlistId: String) -> [SearchResultTrackResponse]? {
		let url = URL(string: "\(config.apiLocation)playlists/\(playlistId)/tracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		var playlistTracksResponse: SearchResultTracksResponse?
		do {
			playlistTracksResponse = try customJSONDecoder().decode(SearchResultTracksResponse.self, from: response.content!)
		} catch {
			displayError(title: "Playlist Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistTracksResponse?.items
	}
	
	func getAlbum(albumId: Int) -> SearchResultAlbumResponse? {
		let url = URL(string: "\(config.apiLocation)albums/\(albumId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		var albumResponse: SearchResultAlbumResponse?
		do {
			albumResponse = try customJSONDecoder().decode(SearchResultAlbumResponse.self, from: response.content!)
		} catch {
			displayError(title: "Album Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumResponse
	}
	
	func getAlbumTracks(albumId: Int) -> [SearchResultTrackResponse]? {
		let url = URL(string: "\(config.apiLocation)albums/\(albumId)/tracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		var albumTracksResponse: SearchResultTracksResponse?
		do {
			albumTracksResponse = try customJSONDecoder().decode(SearchResultTracksResponse.self, from: response.content!)
		} catch {
			displayError(title: "Album Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumTracksResponse?.items
	}
	
	func getArtist(artistId: Int) -> SearchResultArtistResponse? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		var artistResponse: SearchResultArtistResponse?
		do {
			artistResponse = try customJSONDecoder().decode(SearchResultArtistResponse.self, from: response.content!)
		} catch {
			displayError(title: "Artist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistResponse
	}
	
	enum artistAlbumFilter {
		case EPSANDSINGLES
		case COMPILATIONS
	}
	
	func getArtistAlbums(artistId: Int, filter: artistAlbumFilter? = nil) -> [SearchResultAlbumResponse]? {
		var parameters = sessionParameters
		if let filter = filter {
			parameters["filter"] = "\(filter)"
		}
		
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/albums")!
		let response = get(url: url, parameters: parameters)
		
		var artistAlbumsResponse: SearchResultAlbumsResponse?
		do {
			artistAlbumsResponse = try customJSONDecoder().decode(SearchResultAlbumsResponse.self, from: response.content!)
		} catch {
			displayError(title: "Artist Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistAlbumsResponse?.items
	}
	
	func getArtistTopTracks(artistId: Int) -> [SearchResultTrackResponse]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/toptracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		var artistTopTracksResponse: SearchResultTracksResponse?
		do {
			artistTopTracksResponse = try customJSONDecoder().decode(SearchResultTracksResponse.self, from: response.content!)
		} catch {
			displayError(title: "Artist Top Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistTopTracksResponse?.items
	}
	
	func getArtistBio(artistId: Int) -> ArtistBio? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/bio")!
		let response = get(url: url, parameters: sessionParameters)
		
		var artistBio: ArtistBio?
		do {
			artistBio = try customJSONDecoder().decode(ArtistBio.self, from: response.content!)
		} catch {
			displayError(title: "Artist Bio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistBio
	}
	
	func getArtistSimilar(artistId: Int) -> [SearchResultArtistResponse]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/toptracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		var similarArtistsResponse: SearchResultArtistsResponse?
		do {
			similarArtistsResponse = try customJSONDecoder().decode(SearchResultArtistsResponse.self, from: response.content!)
		} catch {
			displayError(title: "Similar Artists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return similarArtistsResponse?.items
	}
	
	func getArtistRadio(artistId: Int) -> [SearchResultTrackResponse]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/toptracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		var artistRadioResponse: SearchResultTracksResponse?
		do {
			artistRadioResponse = try customJSONDecoder().decode(SearchResultTracksResponse.self, from: response.content!)
		} catch {
			displayError(title: "Artist Radio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistRadioResponse?.items
	}
	
	func getUser(userId: Int) -> User? {
		let url = URL(string: "\(config.apiLocation)user/\(userId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		var user: User?
		do {
			user = try customJSONDecoder().decode(User.self, from: response.content!)
		} catch {
			displayError(title: "User failed (JSON Parse Error)", content: "\(error)")
		}
		
		return user
	}
	
	func getUserPlaylists(userId: Int) -> [SearchResultPlaylistResponse]? {
		let url = URL(string: "\(config.apiLocation)user/\(userId)/playlists")!
		let response = get(url: url, parameters: sessionParameters)
		
		var userPlaylistResponse: SearchResultPlaylistsResponse?
		do {
			userPlaylistResponse = try customJSONDecoder().decode(SearchResultPlaylistsResponse.self, from: response.content!)
		} catch {
			displayError(title: "User Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return userPlaylistResponse?.items
	}
}

func displayError(title: String, content: String) {
	// Comment out while unit testing to prevent pop-ups
	
//	print("Error info: \(content)")
//	let appDelegate = NSApplication.shared.delegate as! AppDelegate
//	appDelegate.mainViewController?.errorDialog(title: title, text: content)
}

func readDemoLoginInformation() -> LoginInformation {
	let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
	var content = ""
	do {
		content = try String(contentsOfFile: fileLocation)
	} catch {
		displayError(title: "Couldn't read Demo Login", content: "\(error)")
	}
	
	let lines: [String] = content.components(separatedBy: "\n")
	return LoginInformation(username: lines[0], password: lines[1])
}
