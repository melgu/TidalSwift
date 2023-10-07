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
		self.baseUrl = "\(AuthInformation.APILocation)/users/\(userId)/favorites"
		self.cache = FavoritesCache(favorites: self)
	}
	
	// Return
	
	public func artists(limit: Int = 999, offset: Int = 0, order: ArtistOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteArtist]? {
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
		do {
			let response: FavoriteArtists = try await Network.get(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}

	public func albums(limit: Int = 999, offset: Int = 0, order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteAlbum]? {
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
		do {
			let response: FavoriteAlbums = try await Network.get(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}

	public func tracks(limit: Int = 999, offset: Int = 0, order: TrackOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteTrack]? {
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
		do {
			let response: FavoriteTracks = try await Network.get(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func videos(limit: Int = 100, offset: Int = 0, order: VideoOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteVideo]? {
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
		do {
			let response: FavoriteVideos = try await Network.get(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	/// - Note: Includes User Playlists
	public func playlists(limit: Int = 999, offset: Int = 0, order: PlaylistOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoritePlaylist]? {
		guard let userId = session.userId else {
			return nil
		}
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)/playlistsAndFavoritePlaylists")!
		
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
			do {
				let response: FavoritePlaylists = try await Network.get(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
				// TODO: JSON signature is different
				
				tempPlaylists += response.items
				
				if response.totalNumberOfItems - tempOffset < tempLimit {
					return tempPlaylists
				}
				
				tempLimit -= 50
				tempOffset += 50
			} catch {
				return nil
			}
		}
		
		return tempPlaylists
	}

	public func userPlaylists() async -> [Playlist]? {
		guard let userId = session.userId else {
			displayError(title: "User Playlists failed", content: "User ID not set yet.")
			return nil
		}
		
		return await session.userPlaylists(userId: userId)
	}
	
	// Add
	
	@discardableResult public func addArtist(artistId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/artists")!
		var parameters = session.sessionParameters
		parameters["artistIds"] = "\(artistId)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedArtists()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func addAlbum(albumId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/albums")!
		var parameters = session.sessionParameters
		parameters["albumIds"] = "\(albumId)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedAlbums()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func addTrack(trackId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/tracks")!
		var parameters = session.sessionParameters
		parameters["trackIds"] = "\(trackId)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedTracks()
			return true
		} catch {
			return false
		}
	}
	
	@discardableResult public func addVideo(videoId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/videos")!
		var parameters = session.sessionParameters
		parameters["videoIds"] = "\(videoId)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedVideos()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func addPlaylist(playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/playlists")!
		var parameters = session.sessionParameters
		parameters["uuids"] = playlistId
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedPlaylists()
			return true
		} catch {
			return false
		}
	}
	
	// Delete
	
	@discardableResult public func removeArtist(artistId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/artists/\(artistId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedArtists()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removeAlbum(albumId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/albums/\(albumId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedAlbums()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removeTrack(trackId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/tracks/\(trackId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedTracks()
			return true
		} catch {
			return false
		}
	}
	
	@discardableResult public func removeVideo(videoId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/videos/\(videoId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedVideos()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removePlaylist(playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/playlists/\(playlistId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			await refreshCachedPlaylists()
			return true
		} catch {
			return false
		}
	}
	
	// Check
	
	public func doFavoritesContainArtist(artistId: Int) async -> Bool? {
		guard let artists = await cache.artists else {
			return nil
		}
		for artist in artists where artist.item.id == artistId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainAlbum(albumId: Int) async -> Bool? {
		guard let albums = await cache.albums else {
			return nil
		}
		for album in albums where album.item.id == albumId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainTrack(trackId: Int) async -> Bool? {
		guard let tracks = await cache.tracks else {
			return nil
		}
		for track in tracks where track.item.id == trackId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainVideo(videoId: Int) async -> Bool? {
		guard let videos = await cache.videos else {
			return nil
		}
		for video in videos where video.item.id == videoId {
			return true
		}
		return false
	}
	
	public func doFavoritesContainPlaylist(playlistId: String) async -> Bool? {
		guard let playlists = await cache.playlists else {
			return nil
		}
		for playlist in playlists where playlist.playlist.id == playlistId {
			return true
		}
		return false
	}
	
	// Refresh Caches
	
	private func refreshCachedArtists() async {
		cache.set(await artists())
	}
	
	private func refreshCachedAlbums() async {
		cache.set(await albums())
	}
	
	private func refreshCachedTracks() async {
		cache.set(await tracks())
	}
	
	private func refreshCachedVideos() async {
		cache.set(await videos())
	}
	
	private func refreshCachedPlaylists() async {
		cache.set(await playlists())
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
		get async {
			if Date().timeIntervalSince(lastCheckedArtists) > timeoutInSeconds {
				self._artists = await favorites.artists()
			}
			return _artists
		}
	}
	func set(_ newValue: [FavoriteArtist]?) {
		_artists = newValue
		lastCheckedArtists = .now
	}
	
	private var _albums: [FavoriteAlbum]?
	private var lastCheckedAlbums = Date(timeIntervalSince1970: 0)
	var albums: [FavoriteAlbum]? {
		get async {
			if Date().timeIntervalSince(lastCheckedAlbums) > timeoutInSeconds {
				self._albums = await favorites.albums()
			}
			return _albums
		}
	}
	func set(_ newValue: [FavoriteAlbum]?) {
		_albums = newValue
		lastCheckedAlbums = .now
	}
	
	private var _tracks: [FavoriteTrack]?
	private var lastCheckedTracks = Date(timeIntervalSince1970: 0)
	var tracks: [FavoriteTrack]? {
		get async {
			if Date().timeIntervalSince(lastCheckedTracks) > timeoutInSeconds {
				self._tracks = await favorites.tracks()
			}
			return _tracks
		}
	}
	func set(_ newValue: [FavoriteTrack]?) {
		_tracks = newValue
		lastCheckedTracks = .now
	}
	
	private var _videos: [FavoriteVideo]?
	private var lastCheckedVideos = Date(timeIntervalSince1970: 0)
	var videos: [FavoriteVideo]? {
		get async {
			if Date().timeIntervalSince(lastCheckedVideos) > timeoutInSeconds {
				self._videos = await favorites.videos()
			}
			return _videos
		}
	}
	func set(_ newValue: [FavoriteVideo]?) {
		_videos = newValue
		lastCheckedVideos = .now
	}
	
	private var _playlists: [FavoritePlaylist]?
	private var lastCheckedPlaylists = Date(timeIntervalSince1970: 0)
	var playlists: [FavoritePlaylist]? {
		get async {
			if Date().timeIntervalSince(lastCheckedPlaylists) > timeoutInSeconds {
				self._playlists = await favorites.playlists()
			}
			return _playlists
		}
	}
	func set(_ newValue: [FavoritePlaylist]?) {
		_playlists = newValue
		lastCheckedPlaylists = .now
	}
}
