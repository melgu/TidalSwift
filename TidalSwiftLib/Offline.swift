//
//  Offline.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 12.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

// MARK: DB

public class OfflineDB {
	let semaphore = DispatchSemaphore(value: 1)
	
	// [Track: ByHowManyNeeded]
	var tracks: [Track: Int] = [:] {
		didSet {
			save()
		}
	}
	var favoriteTracks: [Track] = [] { // Used for Favorites
		didSet {
			save()
		}
	}
	var albums: [Album] = [] {
		didSet {
			save()
		}
	}
	var playlists: [Playlist] = [] {
		didSet {
			save()
		}
	}
	var playlistTracks: [Playlist: [Track]] = [:] {
		didSet {
			save()
		}
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
		UserDefaults.standard.synchronize()
		let favoriteTracksData = try? JSONEncoder().encode(favoriteTracks)
		UserDefaults.standard.set(favoriteTracksData, forKey: "OfflineDB:FavoriteTracks")
		UserDefaults.standard.synchronize()
		let albumsData = try? JSONEncoder().encode(albums)
		UserDefaults.standard.set(albumsData, forKey: "OfflineDB:Albums")
		UserDefaults.standard.synchronize()
		let playlistsData = try? JSONEncoder().encode(playlists)
		UserDefaults.standard.set(playlistsData, forKey: "OfflineDB:Playlists")
		UserDefaults.standard.synchronize()
		let playlistTracksData = try? JSONEncoder().encode(playlistTracks)
		UserDefaults.standard.set(playlistTracksData, forKey: "OfflineDB:PlaylistTracks")
		UserDefaults.standard.synchronize()
	}
}

// MARK: - Offline

public class Offline {
	private unowned let session: Session
	private let downloadStatus: DownloadStatus
	private let mainPath = "TidalSwift Offline Library"
	public var uiRefreshFunc: () -> Void = {}
	
	private let db = OfflineDB()
	public var saveFavoritesOffline: Bool = false {
		didSet {
			UserDefaults.standard.set(saveFavoritesOffline, forKey: "SaveFavoritesOffline")
			UserDefaults.standard.synchronize()
		}
	}
	
	private var dispatchQueue = DispatchQueue(label: "melgu.TidalSwift.offline", qos: .background)
	
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
				print("Offline: Library Folder doesn't exist. Creating. Also resetting DB.")
				try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
				db.clear()
			}
		} catch {
			displayError(title: "Offline: Error while creating Offline management class", content: "Error: \(error)")
		}
		
		saveFavoritesOffline = UserDefaults.standard.bool(forKey: "SaveFavoritesOffline")
	}
	
	public func url(for track: Track) -> URL? {
		if !db.tracks.contains(where: { (t, _) in t == track }) {
			return nil
		}
		guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id).m4a") else {
			return nil
		}
		return URL(fileURLWithPath: path.path)
	}
	
	// The following always show the goal state (planned), i.e., after all downloads have finished
	public func numberOfOfflineTracks() -> Int {
		return db.tracks.count
	}
	public func allOfflineTracks() -> [Track]? {
		return db.tracks.map { (track, _) in track }
	}
	
	public func numberOfOfflineAlbums() -> Int {
		return db.albums.count
	}
	public func allOfflineAlbums() -> [Album]? {
		return db.albums
	}
	
	public func numberOfOfflinePlaylists() -> Int {
		return db.playlists.count
	}
	public func allOfflinePlaylists() -> [Playlist]? {
		return db.playlists
	}
	
	public func isTrackMarkedForOffline(track: Track) -> Bool {
		return db.tracks[track] != nil
	}
	
	// Actual state
	private func loadOfflineTrackIds() -> [Int]? {
		var localTracksIds: [Int] = []
		
		do {
			guard let path = buildPath(baseLocation: .music, parentFolder: nil, name: mainPath) else {
				displayError(title: "Offline: Error loading Track IDs on Disk", content: "Error while building path to: \(mainPath)")
				return nil
			}
			let directoryContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
			
			for url in directoryContents {
				var name = url.lastPathComponent
				name.removeLast(4) // Remove ".m4a"
				if let id = Int(name) {
					localTracksIds.append(id)
				}
			}
		}
		catch {
			displayError(title: "Offline: Couldn't load Track IDs from Disk", content: error.localizedDescription)
			return nil
		}
		
		return localTracksIds
	}
	
	private var offlineTrackIdsCache: [Int]? = nil
	private var offlineTrackIdsCacheIntact = false
	private var offlineTrackIdsCacheSemaphore = DispatchSemaphore(value: 1)
	private func invalidateOfflineTrackIdsCache() {
		offlineTrackIdsCacheSemaphore.wait()
		offlineTrackIdsCacheIntact = false
		offlineTrackIdsCacheSemaphore.signal()
	}
	
	public func offlineTrackIds() -> [Int]? {
		offlineTrackIdsCacheSemaphore.wait()
		if !offlineTrackIdsCacheIntact {
			offlineTrackIdsCache = loadOfflineTrackIds()
			offlineTrackIdsCacheIntact = true
		}
		let ids = offlineTrackIdsCache
		offlineTrackIdsCacheSemaphore.signal()
		return ids
	}
	
	public func isTrackOffline(track: Track) -> Bool {
		return offlineTrackIds()?.contains(track.id) ?? false
	}
	
	// MARK: - Sync
	
	private let syncSemaphore = DispatchSemaphore(value: 1)
	private var syncRunning = false
	private var syncAgain = false
	
	private func sync() {
		// Preparations (e.g. setting syncRunning) happen in asyncSync func beforehand
		
		print("Offline: --- Starting Sync ---")
		downloadStatus.startTask()
		
		// Load Local Track IDs
		let dbTracks: [Track] = db.tracks.map { $0.key }
		guard let localTracksIds: [Int] = offlineTrackIds() else {
			displayError(title: "Offline: Sync Error", content: "Couldn't load Tracks from Disk")
			syncSemaphore.wait()
			syncAgain = false
			syncRunning = false
			syncSemaphore.signal()
			return
		}
		print("Offline: DB IDs: \(dbTracks.map { $0.id })")
		print("Offline: Track IDs: \(localTracksIds)")
		
		// Diff
		db.semaphore.wait()
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
		db.semaphore.signal()
		
		// Do
		if !toRemove.isEmpty {
			for trackId in toRemove {
				print("Offline: Removing \(trackId)")
				do {
					guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(trackId).m4a") else {
						displayError(title: "Offline: Error during Offline Sync", content: "Error while building path to: \(mainPath)/\(trackId).m4a")
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
			uiRefreshFunc()
		}
		
		for track in toAdd {
			print("Offline: Downloading \(track.title)")
			guard let url = track.getAudioUrl(session: session) else {
				displayError(title: "Offline: Error while loading offline track", content: "Couldn't get Audio URL")
				return
			}
			guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id).m4a") else {
				displayError(title: "Offline: Error while loading offline track", content: "Error while building path to: \(mainPath)/\(track.id).m4a")
				return
			}
			var response: Response!
			repeat {
				response = Network.download(url, path: path)
			} while response.statusCode == 1001
			
			if !response.ok {
				displayError(title: "Offline: Error while loading offline track", content: "Track: \(track.title). Status Code: \(response.statusCode ?? -1)")
			} else {
				print("Offline: Finished Download of \(track.title)")
			}
			invalidateOfflineTrackIdsCache()
			DispatchQueue.main.async { [unowned self] in
				self.uiRefreshFunc()
			}
		}
		
		// Outro
		syncSemaphore.wait()
		if syncAgain {
			syncAgain = false
			syncSemaphore.signal()
			downloadStatus.finishTask()
			print("Offline: Something changed. Restarting Sync")
			sync()
		} else {
			syncRunning = false
			syncSemaphore.signal()
			downloadStatus.finishTask()
			print("Offline: --- Finished Sync ---")
		}
	}
	
	private var syncWI: DispatchWorkItem?
	private func syncWIBuilder() -> DispatchWorkItem {
		return DispatchWorkItem { [unowned self] in self.sync() }
	}
	
	private func asyncSync() {
		syncSemaphore.wait()
		if syncRunning {
			syncAgain = true // If Sync is requested while running, do another one afterwards
			syncSemaphore.signal()
			return
		}
		syncRunning = true
		syncSemaphore.signal()
		
		syncWI = syncWIBuilder()
		dispatchQueue.async(execute: syncWI!)
	}
	
	// MARK: - Multiple Tracks
	
	private func add(tracks: [Track]) {
		db.semaphore.wait()
		for track in tracks {
			if track.streamReady {
				if let c = db.tracks[track] {
					db.tracks[track] = c + 1
				} else {
					db.tracks[track] = 1
				}
			} else {
				print("Offline: Add. \(track.title) not streamReady, so not added.")
			}
		}
		db.semaphore.signal()
	}
	
	private func remove(tracks: [Track]) {
		db.semaphore.wait()
		for track in tracks {
			if var c = db.tracks[track] {
				c = c - 1
				if c <= 0 {
					db.tracks[track] = nil
				} else {
					db.tracks[track] = c
				}
			}
		}
		db.semaphore.signal()
	}
	
	public func removeAll() {
		print("Offline: Removing all \(db.tracks.count) tracks in \(db.albums.count) albums & \(db.playlists.count) playlists")
		
		syncWI?.cancel()
		syncFavoriteTracksWI?.cancel()
		syncPlaylistsWI?.cancel()
		
		db.semaphore.wait()
		saveFavoritesOffline = false
		db.clear()
		db.semaphore.signal()
		
		asyncSync()
	}
	
	// MARK: - Favorite Tracks
	
	private var favTracksSemaphore = DispatchSemaphore(value: 1)
	private var favTracksSyncRunning = false
	private var favTracksSyncAgain = false
	
	private func syncFavoriteTracks() {
		// Preparations (e.g. setting favTracksSyncRunning) happen in asyncSyncFavoriteTracks func beforehand
		
		// Prepare
		var tracks: [Track] = []
		if saveFavoritesOffline {
			if let favTracks = session.favorites?.tracks() {
				tracks = favTracks.map { $0.item }
			} else {
				displayError(title: "Offline: Error while synchronizing Favorite Tracks", content: "")
				return
			}
		}
		
		// Diff
		db.semaphore.wait()
		var toAdd: [Track] = []
		for track in tracks {
			if track.streamReady && !db.favoriteTracks.contains(track) {
				toAdd.append(track)
			}
		}
		
		var toRemove: [Track] = []
		for track in db.favoriteTracks {
			if !tracks.contains(track) {
				toRemove.append(track)
			}
		}
		db.semaphore.signal()
		
		// Do
		add(tracks: toAdd)
		remove(tracks: toRemove)
		db.favoriteTracks = tracks
		print("Offline: Favorite Tracks synchronized")
		
		// Outro
		favTracksSemaphore.wait()
		if favTracksSyncAgain {
			favTracksSyncAgain = false
			favTracksSemaphore.signal()
			syncFavoriteTracks()
		} else {
			favTracksSyncRunning = false
			favTracksSemaphore.signal()
			asyncSync()
		}
	}
	
	private var syncFavoriteTracksWI: DispatchWorkItem?
	private func syncFavoriteTracksWIBuilder() -> DispatchWorkItem {
		return DispatchWorkItem { [unowned self] in self.syncFavoriteTracks() }
	}
	
	public func asyncSyncFavoriteTracks() {
		favTracksSemaphore.wait()
		if favTracksSyncRunning {
			favTracksSyncAgain = true // If Sync is requested while running, do another one afterwards
			favTracksSemaphore.signal()
			return
		}
		favTracksSyncRunning = true
		favTracksSemaphore.signal()
		
		syncFavoriteTracksWI = syncFavoriteTracksWIBuilder()
		dispatchQueue.async(execute: syncFavoriteTracksWI!)
	}
	
	// MARK: - Album
	
	public func isAlbumOffline(album: Album) -> Bool {
		return db.albums.contains(album)
	}
	
	// Probably no need to do async, as it's only a single quick call to the Tidal API
	public func add(album: Album) {
		if db.albums.contains(album) {
			print("Offline: Album \(album.title) is offline already. This suggests a bug.")
			return
		}
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			return
		}
		db.semaphore.wait()
		db.albums.append(album)
		db.semaphore.signal()
		add(tracks: tracks)
		asyncSync()
	}
	
	public func remove(album: Album) {
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			return
		}
		remove(tracks: tracks)
		db.semaphore.wait()
		db.albums.removeAll(where: { $0 == album })
		db.semaphore.signal()
		asyncSync()
	}
	
	// MARK: - Playlist
	
	private var playlistSemaphore = DispatchSemaphore(value: 1)
	private var playlistsToSync: [Playlist] = []
	private var playlistSyncRunning = false
	
	public func isPlaylistOffline(playlist: Playlist) -> Bool {
		db.playlists.contains(playlist)
	}
	
	private func syncPlaylists() {
		// Preparations (e.g. setting playlistSyncRunning) happen in syncPlaylist func beforehand
		
		print("Offline: --- Sync Playlist ---")
		
		// Prepare
		playlistSemaphore.wait()
		if playlistsToSync.isEmpty {
			print("Offline: No more Playlists to sync.")
			print("Offline: --- Sync Playlists finished ---")
			playlistSemaphore.signal()
			return
		}
		let playlist = playlistsToSync[0]
		playlistsToSync.remove(at: 0)
		playlistSemaphore.signal()
		
		print("Offline: Sync Playlist: \(playlist.title)")
		
		var tracks: [Track] = []
		db.semaphore.wait() // --- DB Semaphore wait
		let dbTracks: [Track] = db.playlistTracks[playlist] ?? []
		let syncThisPlaylist: Bool = db.playlists.contains(playlist)
		
		if syncThisPlaylist {
			if let playlistTracks = session.getPlaylistTracks(playlistId: playlist.id) {
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
		db.semaphore.signal() // --- DB Semaphore signal
		
		// Do
		add(tracks: toAdd)
		remove(tracks: toRemove)
		db.semaphore.wait()
		db.playlistTracks[playlist] = tracks
		db.semaphore.signal()
		
		// Outro
		playlistSemaphore.wait()
		if !playlistsToSync.isEmpty {
			playlistSemaphore.signal()
			print("Offline: Another Playlist to Sync")
			syncPlaylists()
		} else {
			playlistSyncRunning = false
			playlistSemaphore.signal()
			print("Offline: --- Sync Playlists finished ---")
			asyncSync()
		}
	}
	
	private var syncPlaylistsWI: DispatchWorkItem?
	private func syncPlaylistsWIBuilder() -> DispatchWorkItem {
		return DispatchWorkItem { [unowned self] in self.syncPlaylists() }
	}
	
	public func syncPlaylist(_ playlist: Playlist) {
		playlistSemaphore.wait()
		if !playlistsToSync.contains(playlist) {
			playlistsToSync.append(playlist)
		}
		if !playlistSyncRunning {
			syncPlaylistsWI = syncPlaylistsWIBuilder()
			playlistSemaphore.signal()
			dispatchQueue.async(execute: syncPlaylistsWI!)
		} else {
			playlistSemaphore.signal()
		}
	}
	
	public func add(playlist: Playlist) {
		db.semaphore.wait()
		db.playlists.append(playlist)
		db.semaphore.signal()
		syncPlaylist(playlist)
	}
	
	public func remove(playlist: Playlist) {
		db.semaphore.wait()
		db.playlists.removeAll(where: { $0 == playlist })
		db.semaphore.signal()
		syncPlaylist(playlist)
	}
}
