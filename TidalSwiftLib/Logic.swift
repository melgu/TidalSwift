//
//  Logic.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

// Order

public enum PlaylistOrder: String {
	case date = "DATE"
	case name = "NAME"
}

public typealias ArtistOrder = PlaylistOrder

public enum AlbumOrder: String {
	case date = "DATE"
	case name = "NAME"
	case artist = "ARTIST"
	case releaseDate = "RELEASE_DATE"
}

public enum TrackOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case album = "ALBUM"
	case date = "DATE"
	case length = "LENGTH"
}

public enum VideoOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case date = "DATE"
	case length = "LENGTH"
}

public enum OrderDirection: String {
	case ascending = "ASC"
	case descending = "DESC"
}

// Login

public struct LoginCredentials {
	var username: String
	var password: String
	
	public init(username: String, password: String) {
		self.username = username
		self.password = password
	}
}

struct PersistentInformation {
	var sessionId: String
	var countryCode: String
	var userId: Int
}

public class Config {
	var quality: AudioQuality
	var apiLocation: String
	var apiToken: String
	var imageLocation: String
	var imageSize: Int
	var loginCredentials: LoginCredentials
	
	public init(quality: AudioQuality = .hifi,
		 loginCredentials: LoginCredentials,
		 apiToken: String? = nil,
		 apiLocation: String = "https://api.tidal.com/v1/",
		 imageLocation: String = "https://resources.tidal.com/images/",
		 imageSize: Int = 1280) {
		self.quality = quality
		self.loginCredentials = loginCredentials
		
		if apiToken == nil {
			self.apiToken = "_DSTon1kC8pABnTw" // Direct ALAC, 1080p Videos
		} else {
			self.apiToken = apiToken!
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

public class Session {
	var config: Config
	
	var sessionId: String?
	var countryCode: String?
	var userId: Int?
	
	var sessionParameters: [String: String] {
		if sessionId == nil || countryCode == nil {
			return [:]
		} else {
			return ["sessionId": sessionId!,
					"countryCode": countryCode!,
					"limit": "999"]
		}
		
	}
	
	public var favorites: Favorites?
	
	public init(config: Config?) {
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
				let imageLocation = persistentInformation["imageLocation"],
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
						  imageLocation: imageLocation,
						  imageSize: imageSize)
		}
		
		if let config = config {
			self.config = config
		} else {
			self.config = loadConfig()! // Still don't like this force-unwrap
		}
		
	}
	
	public func loadSession() {
		let persistentInformationOptional: [String: String]? =
			UserDefaults.standard.dictionary(forKey: "Session Information") as? [String: String]
		
		guard let persistentInformation = persistentInformationOptional else {
			displayError(title: "Couldn't load Session", content: "Persistent Session Information doesn't exist")
			return
		}
		
		sessionId = persistentInformation["sessionId"]
		countryCode = persistentInformation["countryCode"]
		userId = Int(persistentInformation["userId"]!)
		favorites = Favorites(session: self, userId: userId!)
	}
	
	public func saveSession() {
		guard let sessionId = sessionId,
			  let countryCode = countryCode,
			  let userId = userId else {
			displayError(title: "Couldn't save Session Information",
						 content: "Session Information wasn't set yet. You're probably not logged in.")
			return
		}
		
		let persistentInformation: [String: String] = ["sessionId": sessionId,
													   "countryCode": countryCode,
													   "userId": String(userId)]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Session Information")
	}
	
	public func saveConfig() {
		let persistentInformation: [String: String] = ["quality": config.quality.rawValue,
													   "username": config.loginCredentials.username,
													   "password": config.loginCredentials.password,
													   "apiToken": config.apiToken,
													   "apiLocation": config.apiLocation,
													   "imageLocation": config.imageLocation,
													   "imageSize": String(config.imageSize)
													   ]
		
		UserDefaults.standard.set(persistentInformation, forKey: "Config Information")
	}
	
	public func deletePersistantInformation() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}
	
	public func login() -> Bool {
		let url = URL(string: "\(config.apiLocation)/login/username")!
		let parameters: [String: String] = [
			"token": config.apiToken,
			"username": config.loginCredentials.username,
			"password": config.loginCredentials.password
		]
		let response = Network.post(url: url, parameters: parameters)
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
		favorites = Favorites(session: self, userId: userId!)
		return true
	}
	
	public func checkLogin() -> Bool {
		guard let userId = userId, sessionId != nil else {
			return false
		}
		
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/subscription")!
//		print(sessionParameters)
		return Network.get(url: url, parameters: sessionParameters).ok
	}
	
	public func getSubscriptionInfo() -> Subscription? {
		guard let userId = userId else {
			return nil
		}
		
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/subscription")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/offlineUrl")!
		let response = Network.get(url: url, parameters: parameters)
		
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
//		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)/offlineUrl")! // Only returns low quality video
		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)/streamUrl")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getImageUrl(imageId: String, resolution: Int, resolutionY: Int? = nil) -> URL? {
		// Known Sizes (allowed resolutions)
		// Albums: 80, 160, 320, 640, 1280
		// Artists: 160, 320, 480, 750
		// Videos: 80, 160, 320, 640, 750, 1280
		// Playlists: 160, 320, 480, 640, 750
		// Playlists (non-square): 480x320
		// Users: 100, 210
		// FeaturedItem: 1100x800, 550x400 (not square)
		// Mixes: ???
		// Genres: ???
		
		var tempResolutionY: Int
		if resolutionY != nil {
			tempResolutionY = resolutionY!
		} else {
			tempResolutionY = resolution
		}
		
		let path = imageId.replacingOccurrences(of: "-", with: "/")
		let urlString = "\(config.imageLocation)/\(path)/\(resolution)x\(tempResolutionY).jpg"
		return URL(string: urlString)
	}
	
	public func getImage(imageId: String, resolution: Int, resolutionY: Int? = nil) -> NSImage? {
		let urlOrNil = getImageUrl(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
		guard let url = urlOrNil else {
			return nil
		}
		return NSImage(byReferencing: url)
	}
	
	public struct SearchResponse {
		let artists: [Artist]
		let albums: [Album]
		let playlists: [Playlist]
		let tracks: [Track]
		let videos: [Video]
		let topHit: TopHit?
	}
	
	public func search(for term: String, limit: Int = 50, offset: Int = 0) -> SearchResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		// Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300.
		// Can potentially go higher using offset.
		
		let url = URL(string: "\(config.apiLocation)/search/")!
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Search failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var searchResponse: SearchResponse
		do {
			let searchResult = try customJSONDecoder().decode(SearchResult.self, from: content)
			searchResponse = SearchResponse(artists: searchResult.artists.items,
											albums: searchResult.albums.items,
											playlists: searchResult.playlists.items,
											tracks: searchResult.tracks.items,
											videos: searchResult.videos.items,
											topHit: searchResult.topHit)
		} catch {
			displayError(title: "Search failed (JSON Parse Error)", content: "\(error)")
			return nil
		}
		
		return searchResponse
	}
	
	public func getTrack(trackId: Int) -> Track? {
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Track Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var trackResponse: Track?
		do {
			trackResponse = try customJSONDecoder().decode(Track.self, from: content)
		} catch {
			displayError(title: "Track Info Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return trackResponse
	}
	
	// Delete inexistent or unaccessable Tracks from list
	// Detected by checking for nil values
	public func cleanTrackList(_ trackList: [Track]) -> [Track] {
		var result = [Track]()
		for track in trackList {
			if !(track.streamStartDate == nil || track.audioQuality == nil || track.surroundTypes == nil) {
				result.append(track)
			}
		}
		return result
	}
	
	public func getVideo(videoId: Int) -> Video? {
		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Track Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var videoResponse: Video?
		do {
			videoResponse = try customJSONDecoder().decode(Video.self, from: content)
		} catch {
			displayError(title: "Track Info Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return videoResponse
	}
	
	public func getPlaylist(playlistId: String) -> Playlist? {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getPlaylistTracks(playlistId: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getAlbum(albumId: Int) -> Album? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getAlbumTracks(albumId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	func isAlbumCompilation(albumId: Int) -> Bool {
		let optionalTracks = getAlbumTracks(albumId: albumId)
		guard let tracks = optionalTracks else {
			return false
		}
		
		for track in tracks where track.artists != tracks.first?.artists {
			return true
		}
		return false
	}
	
	public func getArtist(artistId: Int) -> Artist? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public enum ArtistAlbumFilter: String {
		case epsAndSingles = "EPSANDSINGLES"
		case appearances = "COMPILATIONS" // No idea, why Tidal has wrong names
	}
	
	public func getArtistAlbums(artistId: Int, filter: ArtistAlbumFilter? = nil, order: AlbumOrder? = nil,
						 orderDirection: OrderDirection? = nil, limit: Int = 999, offset: Int = 0) -> [Album]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let filter = filter {
			parameters["filter"] = "\(filter.rawValue)"
		}
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/albums")!
		let response = Network.get(url: url, parameters: parameters)
		
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
	
	public func getArtistTopTracks(artistId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/toptracks")!
		let response = Network.get(url: url, parameters: sessionParameters)

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
	
	public func getArtistBio(artistId: Int) -> ArtistBio? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/bio")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getArtistSimilar(artistId: Int) -> [Artist]? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/similar")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getArtistRadio(artistId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/radio")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getTrackRadio(trackId: Int, limit: Int = 100, offset: Int = 0) -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/radio")!
		let response = Network.get(url: url, parameters: parameters)
		
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
	
	public func getUser(userId: Int) -> User? {
		let url = URL(string: "\(config.apiLocation)/users/\(userId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getUserPlaylists(userId: Int, order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/playlists")!
		var parameters = sessionParameters
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
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
	
	public func getMixes() -> [MixesItem]? {
		var parameters = sessionParameters
		parameters["deviceType"] = "DESKTOP"
		let url = URL(string: "\(config.apiLocation)/pages/my_collection_my_mixes")!
		let response = Network.get(url: url, parameters: parameters)
		
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
	
	public func getMixPlaylistTracks(mixId: String) -> [Track]? {
		var parameters = sessionParameters
		parameters["mixId"] = "\(mixId)"
		parameters["deviceType"] = "DESKTOP"
		parameters["token"] = "\(config.apiToken)"
		
		let url = URL(string: "\(config.apiLocation)/pages/mix")!
		let response = Network.get(url: url, parameters: parameters)
		
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

	public func getFeatured() -> [FeaturedItem]? {
		let url = URL(string: "\(config.apiLocation)/promotions")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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

	public func getMoods() -> [Mood]? {
		let url = URL(string: "\(config.apiLocation)/moods")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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

	public func getMoodPlaylists(moodPath: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/moods/\(moodPath)/playlists")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	// TODO: There's more to moods and/or genres than playlists
	
	public func getGenres() -> [Genre]? { // Overview over all Genres
		let url = URL(string: "\(config.apiLocation)/genres")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getGenreTracks(genrePath: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genrePath)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	public func getGenreAlbums(genreName: String) -> [Album]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genreName)/albums")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
public 	func getGenrePlaylists(genreName: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genreName)/playlists")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
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
	
	
	// Playlist editing
	// TODO: Excrat to Playlist Class (like Favorites)
	
	func etag(for playlistId: String) -> Int {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		return response.etag!
	}
	
	public func addTrack(_ trackId: Int, to playlistId: String, duplicate: Bool) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/items")!
		var parameters = sessionParameters
		parameters["trackIds"] = "\(trackId)"
		parameters["onDupes"] = duplicate ? "ADD" : "FAIL"
		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId))
		return response.ok
	}
	
	public func removeTrack(index: Int, from playlistId: String) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/items/\(index)")!
		var parameters = sessionParameters
		parameters["order"] = "INDEX"
		parameters["orderDirection"] = "ASC"
		let response = Network.delete(url: url, parameters: parameters, etag: etag(for: playlistId))
		return response.ok
	}
	
	public func moveTrack(from fromIndex: Int, to toIndex: Int, in playlistId: String) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/items/\(fromIndex)")!
		var parameters = sessionParameters
		parameters["toIndex"] = "\(toIndex)"
		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId))
		return response.ok
	}
	
	public func createPlaylist(title: String, description: String) -> Playlist? {
		guard let userId = userId else {
			return nil
		}
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/playlists")!
		var parameters = sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		let response = Network.post(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Playlist Creation failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistResponse: Playlist?
		do {
			playlistResponse = try customJSONDecoder().decode(Playlist.self, from: content)
		} catch {
			displayError(title: "Playlist Creation failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistResponse
	}
	
	public func editPlaylist(playlistId: String, title: String, description: String) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		var parameters = sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}
	
	public func deletePlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		let response = Network.delete(url: url, parameters: sessionParameters, etag: etag(for: playlistId))
		return response.ok
	}
}

public class Favorites {
	
	unowned let session: Session
	let baseUrl: String
	
	public init(session: Session, userId: Int) {
		self.session = session
		self.baseUrl = "\(session.config.apiLocation)/users/\(userId)/favorites"
	}
	
	// Return
	
	public func artists(limit: Int = 999, offset: Int = 0, order: ArtistOrder? = nil,
				 orderDirection: OrderDirection? = nil) -> [FavoriteArtist]? {
		let url = URL(string: "\(baseUrl)/artists")!
		var parameters = session.sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Favorite Artist failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artists: FavoriteArtists?
		do {
			artists = try customJSONDecoder().decode(FavoriteArtists.self, from: content)
		} catch {
			displayError(title: "Favorite Artist failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artists?.items
	}

	public func albums(limit: Int = 999, offset: Int = 0, order: AlbumOrder? = nil,
				orderDirection: OrderDirection? = nil) -> [FavoriteAlbum]? {
		let url = URL(string: "\(baseUrl)/albums")!
		var parameters = session.sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Favorite Albums failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var albums: FavoriteAlbums?
		do {
			albums = try customJSONDecoder().decode(FavoriteAlbums.self, from: content)
		} catch {
			displayError(title: "Favorite Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albums?.items
	}

	public func tracks(limit: Int = 999, offset: Int = 0, order: TrackOrder? = nil,
				orderDirection: OrderDirection? = nil) -> [FavoriteTrack]? {
		let url = URL(string: "\(baseUrl)/tracks")!
		var parameters = session.sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Favorite Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var tracks: FavoriteTracks?
		do {
			tracks = try customJSONDecoder().decode(FavoriteTracks.self, from: content)
		} catch {
			displayError(title: "Favorite Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return tracks?.items
	}
	
	public func videos(limit: Int = 100, offset: Int = 0, order: VideoOrder? = nil,
				orderDirection: OrderDirection? = nil) -> [FavoriteVideo]? {
		guard limit <= 100 else {
			displayError(title: "Favorite Videos failed (Limit too high)", content: "The limit has to be 100 or below.")
			return nil
		}
		
		let url = URL(string: "\(baseUrl)/videos")!
		var parameters = session.sessionParameters
		parameters["limit"] = "\(limit)" // Unlike the rest, here a maximum limit of 100 exists. Error if higher.
		parameters["offset"] = "\(offset)"
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Favorite Videos failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var videos: FavoriteVideos?
		do {
			videos = try customJSONDecoder().decode(FavoriteVideos.self, from: content)
		} catch {
			displayError(title: "Favorite Videos failed (JSON Parse Error)", content: "\(error)")
		}
		
		return videos?.items
	}
	
	// Includes User Playlists
	public func playlists(limit: Int = 999, offset: Int = 0, order: PlaylistOrder? = nil,
				   orderDirection: OrderDirection? = nil) -> [FavoritePlaylist]? {
		let url = URL(string: "\(baseUrl)/playlists")!
		var parameters = session.sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters)
		
		guard let content = response.content else {
			displayError(title: "Favorite Playlists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlists: FavoritePlaylists?
		do {
			playlists = try customJSONDecoder().decode(FavoritePlaylists.self, from: content)
		} catch {
			displayError(title: "Favorite Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlists?.items
	}

	public func userPlaylists() -> [Playlist]? {
		guard let userId = session.userId else {
			displayError(title: "User Playlists failed", content: "User ID not set yet.")
			return nil
		}
		
		return session.getUserPlaylists(userId: userId)
	}
	
	// Add
	
	public func addArtist(artistId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/artists")!
		
		var parameters = session.sessionParameters
		parameters["artistIds"] = "\(artistId)"
		
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}

	public func addAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums")!
		
		var parameters = session.sessionParameters
		parameters["albumIds"] = "\(albumId)"
		
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}

	public func addTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks")!
		
		var parameters = session.sessionParameters
		parameters["trackIds"] = "\(trackId)"
		
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}
	
	public func addVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos")!
		
		var parameters = session.sessionParameters
		parameters["videoIds"] = "\(videoId)"
		
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}

	public func addPlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists")!
		
		var parameters = session.sessionParameters
		parameters["uuids"] = playlistId
		
		let response = Network.post(url: url, parameters: parameters)
		return response.ok
	}
	
	// Delete
	
	public func removeArtist(artistId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/artists/\(artistId)")!
		
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		return response.ok
	}

	public func removeAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums/\(albumId)")!
		
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		return response.ok
	}

	public func removeTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks/\(trackId)")!
		
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		return response.ok
	}
	
	public func removeVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos/\(videoId)")!
		
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		return response.ok
	}

	public func removePlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists/\(playlistId)")!
		
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		return response.ok
	}
}

func displayError(title: String, content: String) {
	// Comment out while unit testing to prevent pop-ups
	
	print("\(title). \(content)")
//	let appDelegate = NSApplication.shared.delegate as! AppDelegate
//	appDelegate.mainViewController?.errorDialog(title: title, text: content)
}

public func readDemoLoginCredentials() -> LoginCredentials {
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

public func readDemoToken() -> String {
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
