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
	case dateAdded = "DATE"
	case name = "NAME"
}

public typealias ArtistOrder = PlaylistOrder

public enum AlbumOrder: String {
	case dateAdded = "DATE"
	case name = "NAME"
	case artist = "ARTIST"
	case releaseDate = "RELEASE_DATE"
}

public enum TrackOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case album = "ALBUM"
	case dateAdded = "DATE"
	case length = "LENGTH"
}

public enum VideoOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case dateAdded = "DATE"
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
	public var quality: AudioQuality
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
	public var sessionConfig: Config { get { return config }}
	
	var sessionId: String?
	var countryCode: String?
	public var userId: Int?
	
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
	public var helpers: Helpers?
	
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
			if let config = loadConfig() {
				self.config = config
			} else {
				self.config = Config(loginCredentials: LoginCredentials(username: "", password: ""))
			}
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
		helpers = Helpers(session: self)
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
	
	public func deletePersistentInformation() {
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
		helpers = Helpers(session: self)
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
	
	public func getTrackCredits(trackId: Int) -> [Credit]? {
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/credits")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Track Credits Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var creditsResponse: [Credit]?
		do {
			creditsResponse = try customJSONDecoder().decode([Credit].self, from: content)
		} catch {
			displayError(title: "Track Credits Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return creditsResponse
	}
	
	// Delete inexistent or unaccessable Tracks from list
	// Detected by checking for nil values
	public func cleanTrackList(_ trackList: [Track]) -> [Track] {
		var result = [Track]()
		for track in trackList {
			if !(track.streamStartDate == nil || track.audioQuality == nil) {
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
	
	public func getAlbumCredits(albumId: Int) -> [Credit]? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)/credits")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Album Credits Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var creditsResponse: [Credit]?
		do {
			creditsResponse = try customJSONDecoder().decode([Credit].self, from: content)
		} catch {
			displayError(title: "Album Credits Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return creditsResponse
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
	
	public func getArtistVideos(artistId: Int, limit: Int = 999, offset: Int = 0) -> [Video]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/videos")!
		let response = Network.get(url: url, parameters: parameters)

		guard let content = response.content else {
			displayError(title: "Artist Videos failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistVideosResponse: Videos?
		do {
			artistVideosResponse = try customJSONDecoder().decode(Videos.self, from: content)
		} catch {
			displayError(title: "Artist Videos failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistVideosResponse?.items
	}
	
	public func getArtistTopTracks(artistId: Int, limit: Int = 999, offset: Int = 0) -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/toptracks")!
		let response = Network.get(url: url, parameters: parameters)

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
	
	func getArtistBio(artistId: Int, linksRemoved: Bool = true) -> ArtistBio? {
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
		
		guard let ab = artistBio else {
			return nil
		}
		
		// <br/> to \n
		let regex = try! NSRegularExpression(pattern: #"<br/><br/>|<br/>"#)
		let range = NSMakeRange(0, ab.text.count)
		var alteredText = regex.stringByReplacingMatches(in: ab.text, options: [], range: range, withTemplate: "\n\n")
		
		if linksRemoved {
			let regex = try! NSRegularExpression(pattern: #"(\[wimpLink.+?\])|(\[\/wimpLink\])"#)
			let range = NSMakeRange(0, alteredText.count)
			alteredText = regex.stringByReplacingMatches(in: alteredText, options: [], range: range, withTemplate: "")
		}
		
		return ArtistBio(source: ab.source, lastUpdated: ab.lastUpdated, text: alteredText)
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
		
		var moodsResponse: [Mood]?
		do {
			moodsResponse = try customJSONDecoder().decode([Mood].self, from: content)
		} catch {
			displayError(title: "Mood Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return moodsResponse
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
		
		var genresResponse: [Genre]?
		do {
			genresResponse = try customJSONDecoder().decode([Genre].self, from: content)
		} catch {
			displayError(title: "Genre Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresResponse
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
	// TODO: Extract to Playlist Class (like Favorites)
	
	func etag(for playlistId: String) -> Int {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		let response = Network.get(url: url, parameters: sessionParameters)
		return response.etag!
	}
	
	public func addTracks(_ trackIds: [Int], to playlistId: String, duplicate: Bool) -> Bool {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/items")!
		var parameters = sessionParameters
		var trackIdsString = ""
		for id in trackIds {
			trackIdsString += "\(id),"
		}
		trackIdsString = String(trackIdsString.dropLast())
		parameters["trackIds"] = trackIdsString
		parameters["onDupes"] = duplicate ? "ADD" : "FAIL"
		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId))
		return response.ok
	}
	
	public func addTrack(_ trackId: Int, to playlistId: String, duplicate: Bool) -> Bool {
		return addTracks([trackId], to: playlistId, duplicate: duplicate)
	}
	
//	public func addTrack(_ trackId: Int, to playlistId: String, duplicate: Bool) -> Bool {
//		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/items")!
//		var parameters = sessionParameters
//		parameters["trackIds"] = "\(trackId)"
//		parameters["onDupes"] = duplicate ? "ADD" : "FAIL"
//		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId))
//		return response.ok
//	}
	
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
	var cache: FavoritesCache!
	let baseUrl: String
	
	public init(session: Session, userId: Int) {
		self.session = session
		self.baseUrl = "\(session.config.apiLocation)/users/\(userId)/favorites"
		self.cache = FavoritesCache(favorites: self)
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
		guard let userId = session.userId else {
			return nil
		}
		let url = URL(string: "\(session.config.apiLocation)/users/\(userId)/playlistsAndFavoritePlaylists")!
		
		var tempLimit = limit
		var tempOffset = offset
		var tempPlaylists: [FavoritePlaylist] = []
		while tempLimit > 0 {
			print("tempLimit: \(tempLimit), tempOffset: \(tempOffset)")
			var parameters = session.sessionParameters
			if tempLimit > 50 { // Maximum of 50 allowed by Tidal
				parameters["limit"] = "50"
			} else {
				parameters["limit"] = "\(tempLimit)"
			}
			parameters["offset"] = "\(tempOffset)"
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
			
			var playlists: FavoritePlaylists? // TODO: JSON signature is different
			do {
				playlists = try customJSONDecoder().decode(FavoritePlaylists.self, from: content)
			} catch {
				displayError(title: "Favorite Playlists failed (JSON Parse Error)", content: "\(error)")
			}
			
			guard let definitePlaylists = playlists else {
				return nil
			}
			tempPlaylists += definitePlaylists.items
			if definitePlaylists.totalNumberOfItems - tempOffset < tempLimit {
				return tempPlaylists
			}
			
			tempLimit -= 50
			tempOffset += 50
		}
		
		return tempPlaylists
	}

	public func userPlaylists() -> [Playlist]? {
		guard let userId = session.userId else {
			displayError(title: "User Playlists failed", content: "User ID not set yet.")
			return nil
		}
		
		return session.getUserPlaylists(userId: userId)
	}
	
	// Add
	
	@discardableResult public func addArtist(artistId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/artists")!
		var parameters = session.sessionParameters
		parameters["artistIds"] = "\(artistId)"
		let response = Network.post(url: url, parameters: parameters)
		refreshCachedArtists()
		return response.ok
	}

	@discardableResult public func addAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums")!
		var parameters = session.sessionParameters
		parameters["albumIds"] = "\(albumId)"
		let response = Network.post(url: url, parameters: parameters)
		refreshCachedAlbums()
		return response.ok
	}

	@discardableResult public func addTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks")!
		var parameters = session.sessionParameters
		parameters["trackIds"] = "\(trackId)"
		let response = Network.post(url: url, parameters: parameters)
		refreshCachedTracks()
		return response.ok
	}
	
	@discardableResult public func addVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos")!
		var parameters = session.sessionParameters
		parameters["videoIds"] = "\(videoId)"
		let response = Network.post(url: url, parameters: parameters)
		refreshCachedVideos()
		return response.ok
	}

	@discardableResult public func addPlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists")!
		var parameters = session.sessionParameters
		parameters["uuids"] = playlistId
		let response = Network.post(url: url, parameters: parameters)
		refreshCachedPlaylists()
		return response.ok
	}
	
	// Delete
	
	@discardableResult public func removeArtist(artistId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/artists/\(artistId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		refreshCachedArtists()
		return response.ok
	}

	@discardableResult public func removeAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums/\(albumId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		refreshCachedAlbums()
		return response.ok
	}

	@discardableResult public func removeTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks/\(trackId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		refreshCachedTracks()
		return response.ok
	}
	
	@discardableResult public func removeVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos/\(videoId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		refreshCachedVideos()
		return response.ok
	}

	@discardableResult public func removePlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists/\(playlistId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters)
		refreshCachedPlaylists()
		return response.ok
	}
	
	// Check
	
	public func doFavoritesContainArtist(artistId: Int) -> Bool? {
		guard let artists = cache.artists else {
			return nil
		}
		for artist in artists {
			if artist.item.id == artistId {
				return true
			}
		}
		return false
	}
	
	public func doFavoritesContainAlbum(albumId: Int) -> Bool? {
		guard let albums = cache.albums else {
			return nil
		}
		for album in albums {
			if album.item.id == albumId {
				return true
			}
		}
		return false
	}
	
	public func doFavoritesContainTrack(trackId: Int) -> Bool? {
		guard let tracks = cache.tracks else {
			return nil
		}
		for track in tracks {
			if track.item.id == trackId {
				return true
			}
		}
		return false
	}
	
	public func doFavoritesContainVideo(videoId: Int) -> Bool? {
		guard let videos = cache.videos else {
			return nil
		}
		for video in videos {
			if video.item.id == videoId {
				return true
			}
		}
		return false
	}
	
	public func doFavoritesContainPlaylist(playlistId: String) -> Bool? {
		guard let playlists = cache.playlists else {
			return nil
		}
		for playlist in playlists {
			if playlist.playlist.id == playlistId {
				return true
			}
		}
		return false
	}
	
	// Refresh Caches
	
	private func refreshCachedArtists() {
		cache.artists = artists()
	}
	
	private func refreshCachedAlbums() {
		cache.albums = albums()
	}
	
	private func refreshCachedTracks() {
		cache.tracks = tracks()
	}
	
	private func refreshCachedVideos() {
		cache.videos = videos()
	}
	
	private func refreshCachedPlaylists() {
		cache.playlists = playlists()
	}
}

class FavoritesCache {
	unowned let favorites: Favorites
	let timeoutInSeconds: Double
	
	init(favorites: Favorites, timeoutInSeconds: Double = 60) {
		self.favorites = favorites
		self.timeoutInSeconds = timeoutInSeconds
	}
	
	private var _artists: [FavoriteArtist]?
	private var lastCheckedArtists = Date(timeIntervalSince1970: 0)
	var artists: [FavoriteArtist]? {
		get {
			if Date().timeIntervalSince(lastCheckedArtists) > timeoutInSeconds {
				self.artists = favorites.artists()
			}
			return _artists
		}
		set {
			_artists = newValue
			lastCheckedArtists = Date()
		}
	}
	
	private var _albums: [FavoriteAlbum]?
	private var lastCheckedAlbums = Date(timeIntervalSince1970: 0)
	var albums: [FavoriteAlbum]? {
		get {
			if Date().timeIntervalSince(lastCheckedAlbums) > timeoutInSeconds {
				self.albums = favorites.albums()
			}
			return _albums
		}
		set {
			_albums = newValue
			lastCheckedAlbums = Date()
		}
	}
	
	private var _tracks: [FavoriteTrack]?
	private var lastCheckedTracks = Date(timeIntervalSince1970: 0)
	var tracks: [FavoriteTrack]? {
		get {
			if Date().timeIntervalSince(lastCheckedTracks) > timeoutInSeconds {
				self.tracks = favorites.tracks()
			}
			return _tracks
		}
		set {
			_tracks = newValue
			lastCheckedTracks = Date()
		}
	}
	
	private var _videos: [FavoriteVideo]?
	private var lastCheckedVideos = Date(timeIntervalSince1970: 0)
	var videos: [FavoriteVideo]? {
		get {
			if Date().timeIntervalSince(lastCheckedVideos) > timeoutInSeconds {
				self.videos = favorites.videos()
			}
			return _videos
		}
		set {
			_videos = newValue
			lastCheckedVideos = Date()
		}
	}
	
	private var _playlists: [FavoritePlaylist]?
	private var lastCheckedPlaylists = Date(timeIntervalSince1970: 0)
	var playlists: [FavoritePlaylist]? {
		get {
			if Date().timeIntervalSince(lastCheckedPlaylists) > timeoutInSeconds {
				self.playlists = favorites.playlists()
			}
			return _playlists
		}
		set {
			_playlists = newValue
			lastCheckedPlaylists = Date()
		}
	}
}

func displayError(title: String, content: String) {
	// Comment out while unit testing to prevent pop-ups
	
	print("\(title). \(content)")
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
