//
//  Logic.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Cocoa

struct LoginCredentials {
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
	var loginInformation: LoginCredentials
	
	init(quality: Quality = .LOSSLESS,
		 apiLocation: String = "https://api.tidalhifi.com/v1/",
		 apiToken: String? = nil,
		 imageUrl: String = "http://images.osl.wimpmusic.com/im/im/",
		 imageSize: Int = 1280,
		 loginInformation: LoginCredentials) {
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
						  loginInformation: LoginCredentials(username: persistentInformation["username"]!,
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
		
		guard let content = response.content else {
			displayError(title: "Login failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var loginResponse: LoginResponse
		do {
			loginResponse = try JSONDecoder().decode(LoginResponse.self, from: content)
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
	
	func getSubscriptionInfo() -> Subscription? {
		guard let userId = userId else {
			return nil
		}
		
		let url = URL(string: "\(config.apiLocation)users/\(userId)/subscription")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Subscription Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var searchResultResponse: Subscription?
		do {
			searchResultResponse = try customJSONDecoder().decode(Subscription.self, from: content)
		} catch {
			displayError(title: "Subscription Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	// Only works for music tracks (no videos at the moment)
	func getMediaUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality)"
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/streamUrl")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Couldn't get media URL (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var mediaUrlResponse: MediaUrl?
		do {
			mediaUrlResponse = try JSONDecoder().decode(MediaUrl.self, from: content)
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
	
	func search(for term: String, limit: Int = 50, offset: Int = 0) -> SearchResult? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		// Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300.
		// Can potentially go higher using offset.
		
		let url = URL(string: "\(config.apiLocation)search/")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Search failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var searchResultResponse: SearchResult?
		do {
			searchResultResponse = try customJSONDecoder().decode(SearchResult.self, from: content)
		} catch {
			displayError(title: "Search failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	func getPlaylist(playlistId: String) -> Playlist? {
		let url = URL(string: "\(config.apiLocation)playlists/\(playlistId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Playlist Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistResponse: Playlist?
		do {
			playlistResponse = try customJSONDecoder().decode(Playlist.self, from: content)
		} catch {
			displayError(title: "Playlist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistResponse
	}
	
	func getPlaylistTracks(playlistId: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)playlists/\(playlistId)/tracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Playlist Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistTracksResponse: Tracks?
		do {
			playlistTracksResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Playlist Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistTracksResponse?.items
	}
	
	func getAlbum(albumId: Int) -> Album? {
		let url = URL(string: "\(config.apiLocation)albums/\(albumId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Album Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var albumResponse: Album?
		do {
			albumResponse = try customJSONDecoder().decode(Album.self, from: content)
		} catch {
			displayError(title: "Album Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumResponse
	}
	
	func getAlbumTracks(albumId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)albums/\(albumId)/tracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Album Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var albumTracksResponse: Tracks?
		do {
			albumTracksResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Album Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumTracksResponse?.items
	}
	
	func getArtist(artistId: Int) -> Artist? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Artist Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistResponse: Artist?
		do {
			artistResponse = try customJSONDecoder().decode(Artist.self, from: content)
		} catch {
			displayError(title: "Artist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistResponse
	}
	
	enum artistAlbumFilter {
		case EPSANDSINGLES
		case COMPILATIONS
	}
	
	func getArtistAlbums(artistId: Int, filter: artistAlbumFilter? = nil) -> [Album]? {
		var parameters = sessionParameters
		if let filter = filter {
			parameters["filter"] = "\(filter)"
		}
		
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/albums")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Artist Albums failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistAlbumsResponse: Albums?
		do {
			artistAlbumsResponse = try customJSONDecoder().decode(Albums.self, from: content)
		} catch {
			displayError(title: "Artist Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistAlbumsResponse?.items
	}
	
	func getArtistTopTracks(artistId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/toptracks")!
		let response = get(url: url, parameters: sessionParameters)

		guard let content = response.content else {
			displayError(title: "Artist Top Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistTopTracksResponse: Tracks?
		do {
			artistTopTracksResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Artist Top Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistTopTracksResponse?.items
	}
	
	func getArtistBio(artistId: Int) -> ArtistBio? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/bio")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Artist Bio failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistBio: ArtistBio?
		do {
			artistBio = try customJSONDecoder().decode(ArtistBio.self, from: content)
		} catch {
			displayError(title: "Artist Bio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistBio
	}
	
	func getArtistSimilar(artistId: Int) -> [Artist]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/similar")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Similar Artists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var similarArtistsResponse: Artists?
		do {
			similarArtistsResponse = try customJSONDecoder().decode(Artists.self, from: content)
		} catch {
			displayError(title: "Similar Artists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return similarArtistsResponse?.items
	}
	
	func getArtistRadio(artistId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)artists/\(artistId)/radio")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Artist Radio failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistRadioResponse: Tracks?
		do {
			artistRadioResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Artist Radio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistRadioResponse?.items
	}
	
	func getTrackRadio(trackId: Int, limit: Int = 100, offset: Int = 0) -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/radio")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Track Radio (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var trackRadioResponse: Tracks?
		do {
			trackRadioResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Track Radio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return trackRadioResponse?.items
	}
	
	func getUser(userId: Int) -> User? {
		let url = URL(string: "\(config.apiLocation)users/\(userId)")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "User Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var user: User?
		do {
			user = try customJSONDecoder().decode(User.self, from: content)
		} catch {
			displayError(title: "User Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return user
	}
	
	func getUserPlaylists(userId: Int) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)users/\(userId)/playlists")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "User Playlists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var userPlaylistResponse: Playlists?
		do {
			userPlaylistResponse = try customJSONDecoder().decode(Playlists.self, from: content)
		} catch {
			displayError(title: "User Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return userPlaylistResponse?.items
	}
	
//	func getMixes() -> <#return type#> {
//		<#function body#>
//	}
//
//	func getFeatured() -> <#return type#> {
//		<#function body#>
//	}
//
//	func getFeaturedItems() -> <#return type#> {
//		<#function body#>
//	}
//
//	func getMoods() -> <#return type#> {
//		<#function body#>
//	}
//
//	func getMoodPlaylists() -> <#return type#> {
//		<#function body#>
//	}
	
	func getGenres() -> [Genre]? { // Overview over all Genres
		let url = URL(string: "\(config.apiLocation)genres")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresResponse: Genres?
		do {
			genresResponse = try customJSONDecoder().decode(Genres.self, from: content)
		} catch {
			displayError(title: "Genre Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresResponse?.items
	}
	
	// Haven't found Artists in there yet, so only Tracks, Albums & Playlists
	
	func getGenreTracks(genreName: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)genres/\(genreName)/tracks")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genreTracks: Tracks?
		do {
			genreTracks = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Genre Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genreTracks?.items
	}
	
	func getGenreAlbums(genreName: String) -> [Album]? {
		let url = URL(string: "\(config.apiLocation)genres/\(genreName)/albums")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Albums failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresAlbums: Albums?
		do {
			genresAlbums = try customJSONDecoder().decode(Albums.self, from: content)
		} catch {
			displayError(title: "Genre Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresAlbums?.items
	}
	
	func getGenrePlaylists(genreName: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)genres/\(genreName)/playlists")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Playlists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresPlaylists: Playlists?
		do {
			genresPlaylists = try customJSONDecoder().decode(Playlists.self, from: content)
		} catch {
			displayError(title: "Genre Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresPlaylists?.items
	}
}

func displayError(title: String, content: String) {
	// Comment out while unit testing to prevent pop-ups
	
	print("Error info: \(content)")
//	let appDelegate = NSApplication.shared.delegate as! AppDelegate
//	appDelegate.mainViewController?.errorDialog(title: title, text: content)
}

func readDemoLoginInformation() -> LoginCredentials {
	let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
	var content = ""
	do {
		content = try String(contentsOfFile: fileLocation)
	} catch {
		displayError(title: "Couldn't read Demo Login", content: "\(error)")
	}
	
	let lines: [String] = content.components(separatedBy: "\n")
	return LoginCredentials(username: lines[0], password: lines[1])
}
