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
	// [Track: ByHowManyNeeded]
	let semaphore = DispatchSemaphore(value: 1)
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
				print("Offline Library Folder doesn't exist. Creating. Also resetting DB.")
				try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
				db.clear()
			}
		} catch {
			displayError(title: "Error while creating Offline management class", content: "Error: \(error)")
		}
		
		saveFavoritesOffline = UserDefaults.standard.bool(forKey: "SaveFavoritesOffline")
	}
	
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
	
	// MARK: - Single Track
	
	public func url(for track: Track) -> URL? {
		if !db.tracks.contains(where: { (t, _) in t == track }) {
			return nil
		}
		guard let path = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id).m4a") else {
			return nil
		}
		return URL(fileURLWithPath: path.path)
	}
	
	public func isTrackOffline(track: Track) -> Bool {
		return db.tracks[track] != nil
	}
	
	private func add(track: Track) -> Bool {
		print("Offline: Add Track \(track.id) - \(track.title)")
		db.semaphore.wait()
		if let counter = db.tracks[track] {
			db.tracks[track] = counter + 1
			print("Offline: Track \(track.title) already exists. Counter: \(db.tracks[track] ?? 0)")
			db.semaphore.signal()
			return true
		}
		db.semaphore.signal()
		
		guard let url = track.getAudioUrl(session: session) else {
			return false
		}
		let optionalPath = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id).m4a")
		guard let path = optionalPath else {
			return false
		}
		var response: Response!
		repeat {
			response = Network.download(url, path: path)
		} while response.statusCode == 1001
		
		if response.ok {
			db.semaphore.wait()
			db.tracks[track] = 1
			db.semaphore.signal()
			print("Offline: Add Track \(track.title) successful. Counter: \(db.tracks[track] ?? 0)")
		}
		return response.ok
	}
	
	private func remove(track: Track) {
//		print("Offline: Remove Track \(track.id) - \(track.title). Counter: \(db.tracks[track] ?? 0)")
		if let counter = db.tracks[track] {
			if counter <= 1 { // Would be 0 after decrement
//				print("Offline: \(track.title). Counter 0, deleting.")
				db.tracks.removeValue(forKey: track)
				// Remove from db.tracks instead of setting 0 to save space and allow simpler counting
			} else {
				db.tracks[track] = counter - 1
//				print("Offline: \(track.title). Counter above 0, so not removing. New counter \(db.tracks[track] ?? 0)")
				return
			}
		} else {
			displayError(title: "Error while removing offline track", content: "Missing Counter. Trying to delete anyways.")
		}
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			path.appendPathComponent("\(track.id).m4a")
			if FileManager.default.fileExists(atPath: path.relativePath) {
				try FileManager.default.removeItem(at: path)
			}
		} catch {
			displayError(title: "Error while removing offline track", content: "Error: \(error)")
		}
	}
	
	// MARK: - Multiple Tracks
	
	public func areTracksOffline(tracks: [Track]) -> Bool {
		for track in tracks {
			if !isTrackOffline(track: track) {
				return false
			}
		}
		return true
	}
	
	// Returns true if at least one of the track is offline afterwards.
	// WARNING: Doesn't guarantee that all tracks are offline.
	private func add(tracks: [Track]) -> Bool {
		downloadStatus.startTask()
		let group = DispatchGroup()
		let semaphore = DispatchSemaphore(value: 1)
		var result = true
		for track in tracks {
			group.enter()
			dispatchQueue.async { [unowned self] in
				let r = self.add(track: track)
				semaphore.wait()
				result = result || r
				semaphore.signal()
				group.leave()
			}
		}
		group.wait()
		downloadStatus.finishTask()
		return result
	}
	
	private func remove(tracks: [Track]) {
		for track in tracks {
			remove(track: track)
		}
	}
	
	public func removeAll() {
		print("Removing all \(db.tracks.count) tracks in \(db.albums.count) albums & \(db.playlists.count) playlists")
		
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			if FileManager.default.fileExists(atPath: path.relativePath) {
				try FileManager.default.removeItem(at: path)
			}
		} catch {
			displayError(title: "Error while removing all offline tracks", content: "Error: \(error)")
		}
		
		saveFavoritesOffline = false
		db.clear()
//		downloadStatus.downloadingTasks = 0 // WARNING: downloadStatus is not exclusive to Offline
	}
	
	// MARK: - Favorite Tracks
	
	private var favoriteTrackSyncOngoing = false
	private var favTracksSemaphore = DispatchSemaphore(value: 1)
	
	public func syncFavoriteTracks() {
		favTracksSemaphore.wait()
		if favoriteTrackSyncOngoing {
			favTracksSemaphore.signal()
			return
		}
		favoriteTrackSyncOngoing = true
		favTracksSemaphore.signal()
		
		
		downloadStatus.startTask()
		var tracks: [Track] = []
		if saveFavoritesOffline {
			if let favTracks = session.favorites?.tracks() {
				tracks = favTracks.map { $0.item }
			} else {
				displayError(title: "Error while synchronizing Favorite Tracks", content: "")
				downloadStatus.finishTask()
				return
			}
		}
		
		var toAdd: [Track] = []
		for track in tracks {
			if !db.favoriteTracks.contains(track) {
				toAdd.append(track)
			}
		}
		
		var toRemove: [Track] = []
		for track in db.favoriteTracks {
			if !tracks.contains(track) {
				toRemove.append(track)
			}
		}
		
		if add(tracks: toAdd) {
			remove(tracks: toRemove)
			db.favoriteTracks = tracks
		} else {
			displayError(title: "Error while synchronizing Favorite Tracks", content: "Couldn't add missing tracks to Offline.")
		}
		print("Favorite Tracks synchronized")
		downloadStatus.finishTask()
		
		favTracksSemaphore.wait()
		favoriteTrackSyncOngoing = false
		favTracksSemaphore.signal()
	}
	
	// MARK: - Album
	
	public func isAlbumOffline(album: Album) -> Bool {
		return db.albums.contains(album)
	}
	
	public func add(album: Album) -> Bool {
		downloadStatus.startTask()
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			downloadStatus.finishTask()
			return false
		}
		db.albums.append(album)
		downloadStatus.finishTask()
		return add(tracks: tracks)
	}
	
	public func remove(album: Album) {
		if let tracks = session.getAlbumTracks(albumId: album.id) {
			remove(tracks: tracks)
			db.albums.removeAll(where: { $0 == album })
		}
	}
	
	// MARK: - Playlist
	
	private var playlistSemaphore = DispatchSemaphore(value: 1)
	
	public func isPlaylistOffline(playlist: Playlist) -> Bool {
		db.playlists.contains(playlist)
	}
	
	public func syncPlaylist(_ playlist: Playlist) {
		playlistSemaphore.wait()
		
		var tracks: [Track] = []
		let dbTracks: [Track] = db.playlistTracks[playlist] ?? []
		let syncThisPlaylist: Bool = db.playlists.contains(playlist)
		
		if syncThisPlaylist {
			downloadStatus.startTask()
			if let playlistTracks = session.getPlaylistTracks(playlistId: playlist.id) {
				tracks = playlistTracks
			} else {
				displayError(title: "Error while synchronizing Playlist Tracks", content: "Couldn't load playlist tracks from Tidal API.")
				downloadStatus.finishTask()
				return
			}
		} else {
			print("Playlist isn't marked to be offline, so deleting offline tracks, if there are any")
		}
		
		var toAdd: [Track] = []
		for track in tracks {
			if !dbTracks.contains(track) {
				toAdd.append(track)
			}
		}
		
		var toRemove: [Track] = []
		for track in dbTracks {
			if !tracks.contains(track) {
				toRemove.append(track)
			}
		}
		
		if add(tracks: toAdd) {
			remove(tracks: toRemove)
			db.playlistTracks[playlist] = tracks
		} else {
			displayError(title: "Error while synchronizing Playlist Tracks", content: "Couldn't add missing playlist tracks to Offline.")
		}
		if syncThisPlaylist {
			downloadStatus.finishTask()
		}
		
		playlistSemaphore.signal()
	}
	
	public func add(playlist: Playlist) {
		db.playlists.append(playlist)
		syncPlaylist(playlist)
	}

	public func remove(playlist: Playlist) {
		db.playlists.removeAll(where: { $0 == playlist })
		syncPlaylist(playlist)
	}
}
