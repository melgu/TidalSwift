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
	
	public func artists(order: ArtistOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteArtist]? {
		let url = URL(string: "\(baseUrl)/artists")!
		return await allPages(FavoriteArtists.self, url: url, pageSize: 1000, order: order?.rawValue, orderDirection: orderDirection)
	}

	public func albums(order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteAlbum]? {
		let url = URL(string: "\(baseUrl)/albums")!
		return await allPages(FavoriteAlbums.self, url: url, pageSize: 1000, order: order?.rawValue, orderDirection: orderDirection)
	}

	public func tracks(order: TrackOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteTrack]? {
		let url = URL(string: "\(baseUrl)/tracks")!
		return await allPages(FavoriteTracks.self, url: url, pageSize: 1000, order: order?.rawValue, orderDirection: orderDirection)
	}
	
	public func videos(order: VideoOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoriteVideo]? {
		let url = URL(string: "\(baseUrl)/videos")!
		// Unlike the rest, here a maximum limit of 100 exists. Error if higher.
		return await allPages(FavoriteVideos.self, url: url, pageSize: 100, order: order?.rawValue, orderDirection: orderDirection)
	}
	
	/// - Note: Includes User Playlists
	public func playlists(order: PlaylistOrder? = nil, orderDirection: OrderDirection? = nil) async -> [FavoritePlaylist]? {
		guard let userId = session.userId else {
			return nil
		}
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)/playlistsAndFavoritePlaylists")!
		// Maximum of 50 allowed by Tidal
		return await allPages(FavoritePlaylists.self, url: url, pageSize: 50, order: order?.rawValue, orderDirection: orderDirection)
	}
	
	/// Fetches every page, so the result doesn't depend on the order.
	/// - Note: Defaults to newest first, because Tidal's default order isn't stable across pages and repeats or skips items.
	private func allPages<Page: FavoritesPage>(_ pageType: Page.Type, url: URL, pageSize: Int, order: String?, orderDirection: OrderDirection?) async -> [Page.Item]? {
		var items: [Page.Item] = []
		var offset = 0
		while true {
			var parameters = session.sessionParameters
			parameters["limit"] = "\(pageSize)"
			parameters["offset"] = "\(offset)"
			parameters["order"] = order ?? "DATE"
			parameters["orderDirection"] = (orderDirection ?? .descending).rawValue
			do {
				let page: Page = try await session.get(url: url, parameters: parameters)
				items += page.items
				offset += pageSize
				// Pages can come back short, because totalNumberOfItems also counts unavailable items that Tidal leaves out
				if offset >= page.totalNumberOfItems {
					return items
				}
			} catch {
				return nil
			}
		}
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
			_ = try await session.post(url: url, parameters: parameters)
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
			_ = try await session.post(url: url, parameters: parameters)
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
			_ = try await session.post(url: url, parameters: parameters)
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
			_ = try await session.post(url: url, parameters: parameters)
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
			_ = try await session.post(url: url, parameters: parameters)
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
			_ = try await session.delete(url: url, parameters: session.sessionParameters)
			await refreshCachedArtists()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removeAlbum(albumId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/albums/\(albumId)")!
		do {
			_ = try await session.delete(url: url, parameters: session.sessionParameters)
			await refreshCachedAlbums()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removeTrack(trackId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/tracks/\(trackId)")!
		do {
			_ = try await session.delete(url: url, parameters: session.sessionParameters)
			await refreshCachedTracks()
			return true
		} catch {
			return false
		}
	}
	
	@discardableResult public func removeVideo(videoId: Int) async -> Bool {
		let url = URL(string: "\(baseUrl)/videos/\(videoId)")!
		do {
			_ = try await session.delete(url: url, parameters: session.sessionParameters)
			await refreshCachedVideos()
			return true
		} catch {
			return false
		}
	}

	@discardableResult public func removePlaylist(playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/playlists/\(playlistId)")!
		do {
			_ = try await session.delete(url: url, parameters: session.sessionParameters)
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
	private let artistsCache: CachedFavorites<FavoriteArtist>
	private let albumsCache: CachedFavorites<FavoriteAlbum>
	private let tracksCache: CachedFavorites<FavoriteTrack>
	private let videosCache: CachedFavorites<FavoriteVideo>
	private let playlistsCache: CachedFavorites<FavoritePlaylist>
	
	init(favorites: Favorites, timeoutInSeconds: Double = 60) {
		artistsCache = CachedFavorites(timeoutInSeconds: timeoutInSeconds) { [unowned favorites] in await favorites.artists() }
		albumsCache = CachedFavorites(timeoutInSeconds: timeoutInSeconds) { [unowned favorites] in await favorites.albums() }
		tracksCache = CachedFavorites(timeoutInSeconds: timeoutInSeconds) { [unowned favorites] in await favorites.tracks() }
		videosCache = CachedFavorites(timeoutInSeconds: timeoutInSeconds) { [unowned favorites] in await favorites.videos() }
		playlistsCache = CachedFavorites(timeoutInSeconds: timeoutInSeconds) { [unowned favorites] in await favorites.playlists() }
	}
	
	var artists: [FavoriteArtist]? {
		get async { await artistsCache.items }
	}
	func set(_ newValue: [FavoriteArtist]?) {
		artistsCache.set(newValue)
	}
	
	var albums: [FavoriteAlbum]? {
		get async { await albumsCache.items }
	}
	func set(_ newValue: [FavoriteAlbum]?) {
		albumsCache.set(newValue)
	}
	
	var tracks: [FavoriteTrack]? {
		get async { await tracksCache.items }
	}
	func set(_ newValue: [FavoriteTrack]?) {
		tracksCache.set(newValue)
	}
	
	var videos: [FavoriteVideo]? {
		get async { await videosCache.items }
	}
	func set(_ newValue: [FavoriteVideo]?) {
		videosCache.set(newValue)
	}
	
	var playlists: [FavoritePlaylist]? {
		get async { await playlistsCache.items }
	}
	func set(_ newValue: [FavoritePlaylist]?) {
		playlistsCache.set(newValue)
	}
}

private class CachedFavorites<Item> {
	private let timeoutInSeconds: Double
	private let load: () async -> [Item]?
	
	private var value: [Item]?
	private var lastUpdated = Date(timeIntervalSince1970: 0)
	/// Shared by all callers while a reload is running, so concurrent lookups trigger only one request
	private var reloadTask: Task<Void, Never>?
	/// Incremented by set(), so a reload that was running meanwhile doesn't overwrite newer data
	private var generation = 0
	
	init(timeoutInSeconds: Double, load: @escaping () async -> [Item]?) {
		self.timeoutInSeconds = timeoutInSeconds
		self.load = load
	}
	
	var items: [Item]? {
		get async {
			guard Date().timeIntervalSince(lastUpdated) > timeoutInSeconds else {
				return value
			}
			let task = reloadTask ?? startReload()
			await task.value
			return value
		}
	}
	
	func set(_ newValue: [Item]?) {
		value = newValue
		lastUpdated = .now
		reloadTask = nil
		generation += 1
	}
	
	private func startReload() -> Task<Void, Never> {
		let generation = generation
		let task = Task {
			let newValue = await load()
			guard generation == self.generation else {
				return
			}
			reloadTask = nil
			// A failed reload keeps the old data, so the next lookup tries again
			if let newValue {
				set(newValue)
			}
		}
		reloadTask = task
		return task
	}
}
