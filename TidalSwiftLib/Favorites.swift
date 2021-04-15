//
//  Favorites.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

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
		let response = Network.get(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		
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
		let response = Network.get(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		
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
		let response = Network.get(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		
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
		let response = Network.get(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		
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
//			print("tempLimit: \(tempLimit), tempOffset: \(tempOffset)")
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
			let response = Network.get(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
			
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
		let response = Network.post(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedArtists()
		return response.ok
	}

	@discardableResult public func addAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums")!
		var parameters = session.sessionParameters
		parameters["albumIds"] = "\(albumId)"
		let response = Network.post(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedAlbums()
		return response.ok
	}

	@discardableResult public func addTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks")!
		var parameters = session.sessionParameters
		parameters["trackIds"] = "\(trackId)"
		let response = Network.post(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedTracks()
		return response.ok
	}
	
	@discardableResult public func addVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos")!
		var parameters = session.sessionParameters
		parameters["videoIds"] = "\(videoId)"
		let response = Network.post(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedVideos()
		return response.ok
	}

	@discardableResult public func addPlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists")!
		var parameters = session.sessionParameters
		parameters["uuids"] = playlistId
		let response = Network.post(url: url, parameters: parameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedPlaylists()
		return response.ok
	}
	
	// Delete
	
	@discardableResult public func removeArtist(artistId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/artists/\(artistId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedArtists()
		return response.ok
	}

	@discardableResult public func removeAlbum(albumId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/albums/\(albumId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedAlbums()
		return response.ok
	}

	@discardableResult public func removeTrack(trackId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/tracks/\(trackId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedTracks()
		return response.ok
	}
	
	@discardableResult public func removeVideo(videoId: Int) -> Bool {
		let url = URL(string: "\(baseUrl)/videos/\(videoId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedVideos()
		return response.ok
	}

	@discardableResult public func removePlaylist(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/playlists/\(playlistId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, authorization: session.authorization, xTidalToken: session.config.apiToken)
		refreshCachedPlaylists()
		return response.ok
	}
	
	// Check
	
	public func doFavoritesContainArtist(artistId: Int) -> Bool? {
		guard let artists = cache.artists else {
			return nil
		}
		for artist in artists where artist.item.id == artistId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainAlbum(albumId: Int) -> Bool? {
		guard let albums = cache.albums else {
			return nil
		}
		for album in albums where album.item.id == albumId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainTrack(trackId: Int) -> Bool? {
		guard let tracks = cache.tracks else {
			return nil
		}
		for track in tracks where track.item.id == trackId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainVideo(videoId: Int) -> Bool? {
		guard let videos = cache.videos else {
			return nil
		}
		for video in videos where video.item.id == videoId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainPlaylist(playlistId: String) -> Bool? {
		guard let playlists = cache.playlists else {
			return nil
		}
		for playlist in playlists where playlist.playlist.id == playlistId {
			return true
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
