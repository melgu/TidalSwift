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

class Config {
	var quality: AudioQuality
	var apiLocation: String
	var apiToken: String
	var imageUrl: String
	var imageSize: Int
	var loginCredentials: LoginCredentials
	
	init(quality: AudioQuality = .hifi,
		 loginCredentials: LoginCredentials,
		 apiToken: String? = nil,
		 apiLocation: String = "https://api.tidal.com/v1/",
		 imageUrl: String = "http://images.osl.wimpmusic.com/im/im/",
		 imageSize: Int = 1280) {
		self.quality = quality
		self.loginCredentials = loginCredentials
		
		// Custom token from web browser required to load 1080p videos
		// Otherwise videos are limited to 720p
		// Everything else (incl. Master) works though
		if apiToken == nil {
			if quality == .hifi {
				self.apiToken = "P5Xbeo5LFvESeDy6"
			} else {
				self.apiToken = "wdgaB1CilGA-S_s2"
			}
		} else {
			self.apiToken = apiToken!
		}
		
		self.apiLocation = apiLocation
		self.imageUrl = imageUrl
		self.imageSize = imageSize
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
			
			guard let qualityString = persistentInformation["quality"],
				let quality = AudioQuality(rawValue: qualityString),
				let username = persistentInformation["username"],
				let password = persistentInformation["password"],
				let apiToken = persistentInformation["apiToken"],
				let apiLocation = persistentInformation["apiLocation"],
				let imageUrl = persistentInformation["imageUrl"],
				let imageSizeString = persistentInformation["imageSize"],
				let imageSize = Int(imageSizeString)
			else {
				displayError(title: "Couldn't load Config", content: "Missing part of Persistent Config")
				return nil
			}
			
			return Config(quality: quality,
						  loginCredentials: LoginCredentials(username: username,
															 password: password),
						  apiToken: apiToken,
						  apiLocation: apiLocation,
						  imageUrl: imageUrl,
						  imageSize: imageSize)
		}
		
		if let config = config {
			self.config = config
		} else {
			self.config = loadConfig()! // Still don't like this force-unwrap
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
		let persistentInformation: [String: String] = ["quality": config.quality.rawValue,
													   "username": config.loginCredentials.username,
													   "password": config.loginCredentials.password,
													   "apiToken": config.apiToken,
													   "apiLocation": config.apiLocation,
													   "imageUrl": config.imageUrl,
													   "imageSize": String(config.imageSize),
													   ]
		
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
			"username": config.loginCredentials.username,
			"password": config.loginCredentials.password
		]
		let response = post(url: url, parameters: parameters)
		if !response.ok {
			if response.statusCode == 401 { // Wrong Username / Password
				displayError(title: "Wrong username or password",
							 content: "Username, password, token, or API Location is wrong.")
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
	func getAudioUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality.rawValue)"
		let url = URL(string: "\(config.apiLocation)tracks/\(trackId)/streamUrl")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Couldn't get Audio URL (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var audioUrlResponse: AudioUrl?
		do {
			audioUrlResponse = try JSONDecoder().decode(AudioUrl.self, from: content)
		} catch {
			displayError(title: "Couldn't get Audio URL (JSON Parse Error)", content: "\(error)")
		}
//		print("""
//			Track ID: \(mediaUrlResponse?.trackId ?? -1),
//			Quality: \(mediaUrlResponse?.soundQuality.rawValue ?? ""),
//			Codec: \(mediaUrlResponse?.codec ?? "")
//			""")
		
		return audioUrlResponse?.url
	}
	
	func getVideoUrl(videoId: Int) -> URL? {
		let url = URL(string: "\(config.apiLocation)videos/\(videoId)/streamUrl")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Couldn't get Video URL (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var videoUrlResponse: VideoUrl?
		do {
			videoUrlResponse = try JSONDecoder().decode(VideoUrl.self, from: content)
		} catch {
			displayError(title: "Couldn't get Video URL (JSON Parse Error)", content: "\(error)")
		}
		
		return videoUrlResponse?.url
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
	
	func getMixes() -> [MixesItem]? {
		var parameters = sessionParameters
		parameters["deviceType"] = "DESKTOP"
		let url = URL(string: "\(config.apiLocation)pages/my_collection_my_mixes")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Mixes Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var mixesResponse: Mixes?
		do {
			mixesResponse = try customJSONDecoder().decode(Mixes.self, from: content)
		} catch {
			displayError(title: "Mixes Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return mixesResponse?.rows[0].modules[0].pagedList.items
	}
	
	func getMixPlaylistTracks(mixId: String) -> [Track]? {
		var parameters = sessionParameters
		parameters["mixId"] = "\(mixId)"
		parameters["deviceType"] = "DESKTOP"
		parameters["token"] = "\(config.apiToken)"
		let url = URL(string: "\(config.apiLocation)pages/mix")!
		let response = get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Mix Playlist Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var mixResponse: Mix?
		do {
			mixResponse = try customJSONDecoder().decode(Mix.self, from: content)
		} catch {
			displayError(title: "Mix Playlist Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return mixResponse?.rows[1].modules[0].pagedList?.items
	}

	func getFeatured() -> [FeaturedItem]? {
		let url = URL(string: "\(config.apiLocation)promotions")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Featured failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var featuredResponse: FeaturedItems?
		do {
			featuredResponse = try customJSONDecoder().decode(FeaturedItems.self, from: content)
		} catch {
			displayError(title: "Featured failed (JSON Parse Error)", content: "\(error)")
		}
		
		return featuredResponse?.items
	}

	func getMoods() -> [Mood]? {
		let url = URL(string: "\(config.apiLocation)moods")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Mood Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var moodsResponse: Moods?
		do {
			moodsResponse = try customJSONDecoder().decode(Moods.self, from: content)
		} catch {
			displayError(title: "Mood Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return moodsResponse?.items
	}

	func getMoodPlaylists(moodPath: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)moods/\(moodPath)/playlists")!
		let response = get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var moodPlaylists: Playlists?
		do {
			moodPlaylists = try customJSONDecoder().decode(Playlists.self, from: content)
		} catch {
			displayError(title: "Genre Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return moodPlaylists?.items
	}
	
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
	
	func getGenreTracks(genrePath: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)genres/\(genrePath)/tracks")!
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

func readDemoLoginCredentials() -> LoginCredentials {
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

func readDemoToken() -> String {
	let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
	var content = ""
	do {
		content = try String(contentsOfFile: fileLocation)
	} catch {
		displayError(title: "Couldn't read Demo Token", content: "\(error)")
	}
	
	let lines: [String] = content.components(separatedBy: "\n")
	return lines[2]
}
