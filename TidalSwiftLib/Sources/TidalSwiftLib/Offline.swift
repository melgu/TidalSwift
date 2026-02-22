//
//  Offline.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 12.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

// MARK: DB

public final class OfflineDB {
	// [Track: ByHowManyNeeded]
	private(set) var tracks: [Track: Int] = [:] {
		didSet {
			save()
		}
	}
	func incrementCounter(for track: Track) {
		tracks[track, default: 0] += 1
	}
	func decrementCounter(for track: Track) {
		guard let counter = tracks[track] else { return }
		if counter - 1 <= 0 {
			tracks[track] = nil
		} else {
			tracks[track, default: 0] -= 1
		}
	}
	
	private(set) var favoriteTracks: [Track] = [] { // Used for Favorites
		didSet {
			save()
		}
	}
	func setFavoriteTracks(to tracks: [Track]) {
		favoriteTracks = tracks
	}
	
	var albums: [Album] = [] {
		didSet {
			save()
		}
	}
	func add(_ album: Album) {
		albums.append(album)
	}
	func remove(_ album: Album) {
		albums.removeAll(where: { $0 == album })
	}
	
	var albumTracks: [Album: [Track]] = [:] {
		didSet {
			save()
		}
	}
	func setTracks(for album: Album, to tracks: [Track]?) {
		albumTracks[album] = tracks
	}
	
	var playlists: [Playlist] = [] {
		didSet {
			save()
		}
	}
	func add(_ playlist: Playlist) {
		playlists.append(playlist)
	}
	func remove(_ playlist: Playlist) {
		playlists.removeAll(where: { $0 == playlist })
	}
	
	var playlistTracks: [Playlist: [Track]] = [:] {
		didSet {
			save()
		}
	}
	func setTracks(for playlist: Playlist, to tracks: [Track]?) {
		playlistTracks[playlist] = tracks
	}
	
	init() {
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:Tracks") {
			if let temp = try? JSONDecoder().decode([Track: Int].self, from: data) {
				self.tracks = temp
			} else {
				self.tracks = [:]
			}
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:FavoriteTracks") {
			if let temp = try? JSONDecoder().decode([Track].self, from: data) {
				self.favoriteTracks = temp
			} else {
				self.favoriteTracks = []
			}
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:Albums") {
			if let temp = try? JSONDecoder().decode([Album].self, from: data) {
				self.albums = temp
			} else {
				self.albums = []
			}
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:AlbumTracks") {
			if let temp = try? JSONDecoder().decode([Album: [Track]].self, from: data) {
				self.albumTracks = temp
			} else {
				self.albumTracks = [:]
			}
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:Playlists") {
			if let temp = try? JSONDecoder().decode([Playlist].self, from: data) {
				self.playlists = temp
			} else {
				self.playlists = []
			}
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB:PlaylistTracks") {
			if let temp = try? JSONDecoder().decode([Playlist: [Track]].self, from: data) {
				self.playlistTracks = temp
			} else {
				self.playlistTracks = [:]
			}
		}
	}
	
	func clear() {
		tracks = [:]
		favoriteTracks = []
		albums = []
		playlists = []
		playlistTracks = [:]
	}
	
	private func save() {
		let tracksData = try? JSONEncoder().encode(tracks)
		UserDefaults.standard.set(tracksData, forKey: "OfflineDB:Tracks")
		
		let favoriteTracksData = try? JSONEncoder().encode(favoriteTracks)
		UserDefaults.standard.set(favoriteTracksData, forKey: "OfflineDB:FavoriteTracks")
		
		let albumsData = try? JSONEncoder().encode(albums)
		UserDefaults.standard.set(albumsData, forKey: "OfflineDB:Albums")
		
		let albumTracksData = try? JSONEncoder().encode(albumTracks)
		UserDefaults.standard.set(albumTracksData, forKey: "OfflineDB:AlbumTracks")
		
		let playlistsData = try? JSONEncoder().encode(playlists)
		UserDefaults.standard.set(playlistsData, forKey: "OfflineDB:Playlists")
		
		let playlistTracksData = try? JSONEncoder().encode(playlistTracks)
		UserDefaults.standard.set(playlistTracksData, forKey: "OfflineDB:PlaylistTracks")
	}
}

// MARK: - Offline

public final class Offline {
	private unowned let session: Session
	private let downloadStatus: DownloadStatus
	private let mainPath = "TidalSwift Offline Library"
	@MainActor
	public var uiRefreshFunc: () -> Void = {}
	
	@AppStorage("SaveFavoritesOffline") public var saveFavoritesOffline = false
	
	private let db = OfflineDB()
	
	public init(session: Session, downloadStatus: DownloadStatus) {
		self.session = session
		self.downloadStatus = downloadStatus
		
		// Create main folder if it doesn't exist
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			if !FileManager.default.fileExists(atPath: path.relativePath) {
				print("Offline: Library Folder doesn't exist. Redownloading all Songs.")
				try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
			}
		} catch {
			displayError(title: "Offline: Error while creating Offline management class", content: "Error: \(error)")
		}
		
		Task { await asyncSync() }
	}
	
	public func url(for track: Track, audioQuality: AudioQuality) async -> URL? {
		if await !db.tracks.contains(where: { (t, _) in t == track }) {
			return nil
		}
		guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id)", pathExtension: session.pathExtension(for: audioQuality)) else {
			return nil
		}
		return URL(fileURLWithPath: path.path)
	}
	
	// The following always show the goal state (planned), i.e., after all downloads have finished
	public func numberOfOfflineTracks() async -> Int {
		await db.tracks.count
	}
	public func allOfflineTracks() async -> [Track] {
		await db.tracks.map { (track, _) in track }
	}
	
	public func numberOfOfflineAlbums() async -> Int {
		await db.albums.count
	}
	public func allOfflineAlbums() async -> [Album] {
		await db.albums
	}
	
	public func numberOfOfflinePlaylists() async -> Int {
		await db.playlists.count
	}
	public func allOfflinePlaylists() async -> [Playlist] {
		await db.playlists
	}
	
	public func isTrackMarkedForOffline(track: Track) async -> Bool {
		await db.tracks[track] != nil
	}
	
	// Actual state
	private func loadOfflineTrackIds() -> [Int]? {
		var localTracksIds: [Int] = []
		
		do {
			guard let path = buildPath(baseLocation: .music, parentFolder: nil, name: mainPath, pathExtension: nil) else {
				displayError(title: "Offline: Error loading Track IDs on Disk", content: "Error while building path to: \(mainPath)")
				return nil
			}
			let directoryContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
			for url in directoryContents {
				var name = url.lastPathComponent
				name.removeLast(4) // Remove ".m4a" / ".flac"
				if let id = Int(name) {
					localTracksIds.append(id)
				}
			}
		} catch {
			displayError(title: "Offline: Couldn't load Track IDs from Disk", content: error.localizedDescription)
			return nil
		}
		
		return localTracksIds
	}
	
	private var offlineTrackIdsCache: [Int]?
	private var offlineTrackIdsCacheIntact = false
	private func invalidateOfflineTrackIdsCache() {
		offlineTrackIdsCacheIntact = false
	}
	
	public func offlineTrackIds() -> [Int]? {
		if !offlineTrackIdsCacheIntact {
			offlineTrackIdsCache = loadOfflineTrackIds()
			offlineTrackIdsCacheIntact = true
		}
		let ids = offlineTrackIdsCache
		return ids
	}
	
	public func isTrackOffline(track: Track) -> Bool {
		offlineTrackIds()?.contains(track.id) ?? false
	}
	
	// MARK: - Sync
	
	private var syncRunning = false
	private var syncAgain = false
	
	private func sync() async {
		// Preparations (e.g. setting syncRunning) happen in asyncSync func beforehand
		
		print("Offline: --- Starting Sync ---")
		syncRunning = true
		
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		// Load Local Track IDs
		let dbTracks: [Track] = await db.tracks.map { $0.key }
		guard let localTracksIds: [Int] = offlineTrackIds() else {
			displayError(title: "Offline: Sync Error", content: "Couldn't load Tracks from Disk")
			syncAgain = false
			syncRunning = false
			return
		}
		print("Offline: DB IDs: \(dbTracks.map { $0.id })")
		print("Offline: Track IDs: \(localTracksIds)")
		
		// Diff
		var toRemove: [Int] = []
		for trackId in localTracksIds {
			if !dbTracks.contains(where: { $0.id == trackId }) {
				toRemove.append(trackId)
			}
		}
		
		var toAdd: [Track] = []
		for track in dbTracks {
			if !localTracksIds.contains(track.id) {
				toAdd.append(track)
			}
		}
		
		// Do
		if !toRemove.isEmpty {
			for trackId in toRemove {
				print("Offline: Removing \(trackId)")
				do {
					let pathExtension = session.pathExtension(for: session.config.offlineAudioQuality)
					guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(trackId)", pathExtension: pathExtension) else {
						displayError(title: "Offline: Error during Offline Sync", content: "Error while building path to: \(mainPath)/\(trackId).\(pathExtension)")
						return
					}
					if FileManager.default.fileExists(atPath: path.relativePath) {
						try FileManager.default.removeItem(at: path)
						print("Offline: Removed \(trackId)")
					} else {
						displayError(title: "Offline: Error while removing offline track", content: "File to remove doesn't exist: \(path)")
					}
				} catch {
					displayError(title: "Offline: Error while removing offline track", content: "Error: \(error)")
				}
			}
			invalidateOfflineTrackIdsCache()
			await uiRefreshFunc()
		}
		
		for track in toAdd {
			print("Offline: Downloading \(track.title)")
			guard let url = await track.audioUrl(session: session, audioQuality: session.config.offlineAudioQuality) else {
				displayError(title: "Offline: Error while loading offline track", content: "Couldn't get Audio URL")
				return
			}
			let pathExtension = session.pathExtension(for: session.config.offlineAudioQuality)
			guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id)", pathExtension: pathExtension) else {
				displayError(title: "Offline: Error while loading offline track", content: "Error while building path to: \(mainPath)/\(track.id).\(pathExtension)")
				return
			}
			do {
				try await Network.download(url, path: path)
				print("Offline: Finished Download of \(track.title)")
				invalidateOfflineTrackIdsCache()
				await uiRefreshFunc()
			} catch {
				displayError(title: "Offline: Error while loading offline track", content: "Network error: \(error)")
			}
		}
		
		// Outro
		if syncAgain {
			syncAgain = false
			print("Offline: Something changed. Restarting Sync")
			await sync()
		} else {
			syncRunning = false
			print("Offline: --- Finished Sync ---")
		}
	}
	
	private var syncTask: Task<Void, Never>?
	
	private func asyncSync() {
		if syncRunning {
			syncAgain = true // If Sync is requested while running, do another one afterwards
			return
		}
		
		syncTask = Task { await sync() }
	}
	
	// MARK: - Multiple Tracks
	
	private func add(tracks: [Track]) async {
		for track in tracks {
			if track.streamReady {
				await db.incrementCounter(for: track)
			} else {
				print("Offline: Add. \(track.title) not streamReady, so not added.")
			}
		}
	}
	
	private func remove(tracks: [Track]) async {
		for track in tracks {
			await db.decrementCounter(for: track)
		}
	}
	
	public func removeAll() {
		Task {
			print("Offline: Removing all \(await db.tracks.count) tracks in \(await db.albums.count) albums & \(await db.playlists.count) playlists")
		}
		
		syncTask?.cancel()
		syncFavoriteTracksTask?.cancel()
		syncPlaylistsTask?.cancel()
		
		saveFavoritesOffline = false
		Task {
			await db.clear()
			asyncSync()
		}
	}
	
	// MARK: - Favorite Tracks
	
	private var favTracksSyncRunning = false
	private var favTracksSyncAgain = false
	
	private func syncFavoriteTracks() async {
		// Preparations (e.g. setting favTracksSyncRunning) happen in asyncSyncFavoriteTracks func beforehand
		
		// Prepare
		var tracks: [Track] = []
		if saveFavoritesOffline {
			if let favTracks = await session.favorites?.tracks() {
				tracks = favTracks.map { $0.item }
			} else {
				displayError(title: "Offline: Error while synchronizing Favorite Tracks", content: "")
				return
			}
		}
		
		// Diff
		var toAdd: [Track] = []
		for track in tracks {
			let isFavorite = await db.favoriteTracks.contains(track)
			if track.streamReady && !isFavorite {
				toAdd.append(track)
			}
		}
		
		var toRemove: [Track] = []
		for track in await db.favoriteTracks {
			if !tracks.contains(track) {
				toRemove.append(track)
			}
		}
		
		// Do
		await add(tracks: toAdd)
		await remove(tracks: toRemove)
		await db.setFavoriteTracks(to: tracks)
		print("Offline: Favorite Tracks synchronized")
		
		// Outro
		if favTracksSyncAgain {
			favTracksSyncAgain = false
			await syncFavoriteTracks()
		} else {
			favTracksSyncRunning = false
			asyncSync()
		}
	}
	
	private var syncFavoriteTracksTask: Task<Void, Never>?
	
	private func _asyncSyncFavoriteTracks() {
		if favTracksSyncRunning {
			favTracksSyncAgain = true // If Sync is requested while running, do another one afterwards
			return
		}
		favTracksSyncRunning = true
		
		syncFavoriteTracksTask = Task { await syncFavoriteTracks() }
	}
	
	@MainActor
	public func asyncSyncFavoriteTracks() {
		Task { await _asyncSyncFavoriteTracks() }
	}
	
	// MARK: - Album
	
	public func isAlbumOffline(album: Album) async -> Bool {
		await db.albums.contains(album)
	}
	
	public func getTracks(for album: Album) async -> [Track]? {
		await db.albumTracks[album]
	}
	
	// Probably no need to do async, as it's only a single quick call to the Tidal API
	public func add(album: Album) async {
		if await db.albums.contains(album) {
			print("Offline: Album \(album.title) is offline already. This suggests a bug.")
			return
		}
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return
		}
		await db.add(album)
		await db.setTracks(for: album, to: tracks)
		await add(tracks: tracks)
		asyncSync()
	}
	
	public func remove(album: Album) async {
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return
		}
		await remove(tracks: tracks)
		await db.remove(album)
		await db.setTracks(for: album, to: nil)
		asyncSync()
	}
	
	// MARK: - Playlist
	
	private var playlistsToSync: [Playlist] = []
	private var playlistSyncRunning = false
	
	public func isPlaylistOffline(playlist: Playlist) async -> Bool {
		await db.playlists.contains(playlist)
	}
	
	public func getTracks(for playlist: Playlist) async -> [Track]? {
		await db.playlistTracks[playlist]
	}
	
	private func syncPlaylists() async {
		// Preparations (e.g. setting playlistSyncRunning) happen in syncPlaylist func beforehand
		
		print("Offline: --- Sync Playlist ---")
		
		// Prepare
		if playlistsToSync.isEmpty {
			print("Offline: No more Playlists to sync.")
			print("Offline: --- Sync Playlists finished ---")
			return
		}
		let playlist = playlistsToSync[0]
		playlistsToSync.remove(at: 0)
		
		print("Offline: Sync Playlist: \(playlist.title)")
		
		var tracks: [Track] = []
		let dbTracks: [Track] = await db.playlistTracks[playlist] ?? []
		let syncThisPlaylist = await db.playlists.contains(playlist)
		
		if syncThisPlaylist {
			if let playlistTracks = await session.playlistTracks(playlistId: playlist.id) {
				tracks = playlistTracks
			} else {
				displayError(title: "Offline: Error while synchronizing Playlist Tracks", content: "Couldn't load playlist tracks from Tidal API.")
				return
			}
		} else {
			print("Offline: Playlist isn't marked to be offline, so deleting offline tracks, if there are any")
		}
		
		// Diff
		var toAdd: [Track] = []
		for track in tracks {
			if track.streamReady && !dbTracks.contains(track) {
				toAdd.append(track)
			}
		}
		
		var toRemove: [Track] = []
		for track in dbTracks {
			if !tracks.contains(track) {
				toRemove.append(track)
			}
		}
		print("Offline: Playlist tracks: \(tracks.map { $0.id })")
		print("Offline: Playlist dbTracks: \(dbTracks.map { $0.id })")
		print("Offline: Playlist toAdd: \(toAdd.map { $0.id })")
		print("Offline: Playlist toRemove: \(toRemove.map { $0.id })")
		
		// Do
		await add(tracks: toAdd)
		await remove(tracks: toRemove)
		await db.setTracks(for: playlist, to: tracks)
		
		// Outro
		if !playlistsToSync.isEmpty {
			print("Offline: Another Playlist to Sync")
			await syncPlaylists()
		} else {
			playlistSyncRunning = false
			print("Offline: --- Sync Playlists finished ---")
			asyncSync()
		}
	}
	
	private var syncPlaylistsTask: Task<Void, Never>?
	
	public func syncPlaylist(_ playlist: Playlist) {
		if !playlistsToSync.contains(playlist) {
			playlistsToSync.append(playlist)
		}
		if !playlistSyncRunning {
			playlistSyncRunning = true
			syncPlaylistsTask = Task { await syncPlaylists() }
		}
	}
	
	public func add(playlist: Playlist) async {
		await db.add(playlist)
		syncPlaylist(playlist)
	}
	
	public func remove(playlist: Playlist) async {
		await db.remove(playlist)
		syncPlaylist(playlist)
	}
	
	// Useful at startup to check for changes in all Offline Playlists
	public func syncAllOfflinePlaylistsAndFavoriteTracks() async {
		for playlist in await db.playlists {
			syncPlaylist(playlist)
		}
		_asyncSyncFavoriteTracks()
	}
}
