//
//  Helpers.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Combine
import SDAVAssetExportSession

public final class DownloadStatus: ObservableObject {
	@Published public var downloadingTasks: Int = 0
	var downloadingTasksSet: Int {
		set {
			DispatchQueue.main.sync {
				self.downloadingTasks = newValue
				print("Downloading Tasks: \(newValue)")
			}
		}
		get {
			downloadingTasks
		}
	}
}

// TODO: Maybe present a textform or something other than this
public struct DownloadErrors {
	var affectedTracks = Set<Track>()
	var affectedAlbums = Set<Album>()
	var affectedArtists = Set<Artist>()
	var affectedPlaylists = Set<Playlist>()
}

public class Helpers {
	unowned let session: Session
	public let offline: Offline
	public let downloadStatus = DownloadStatus()
	let metadata: Metadata
	
	public init(session: Session) {
		self.session = session
		self.offline = Offline(session: session, downloadStatus: downloadStatus)
		self.metadata = Metadata(session: session)
	}
	
	public func newReleasesFromFavoriteArtists(number: Int = 30) -> [Album]? {
		let optionalFavoriteArtists = session.favorites?.artists()
		guard let favoriteArtists = optionalFavoriteArtists else {
			return nil
		}
		
		var allReleases = [Album]()
		for artist in favoriteArtists {
			let optionalAlbums = session.getArtistAlbums(artistId: artist.item.id, limit: number)
			guard let albums = optionalAlbums else {
				continue
			}
			allReleases += albums
		}
		
		allReleases.sort { $0.releaseDate! > $1.releaseDate! }
		return Array(allReleases.prefix(number))
	}
	
	// MARK: - Downloading
	
	// TODO: Titles can be a names which the file system doesn't like
	// TODO: Currently everything is done on the main thread synchronously
	
	func formFileName(_ track: Track) -> String {
		return "\(track.trackNumber) \(track.title) - \(track.artists.formArtistString()).m4a"
	}
	
	func formFileName(_ video: Video) -> String {
		return "\(video.trackNumber) \(video.title) - \(video.artists.formArtistString()).mp4"
	}
	
	public func download(track: Track, parentFolder: String = "") -> Bool {
		downloadStatus.downloadingTasksSet += 1
		guard let url = track.getAudioUrl(session: session) else {
			downloadStatus.downloadingTasksSet -= 1
			return false
		}
		print("Downloading \(track.title)")
		let fileName = formFileName(track)
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: fileName)
		guard let path = optionalPath else {
			displayError(title: "Error while downloading track", content: "Couldn't build path for track: \(track.title) -  \(track.artists.formArtistString())")
			downloadStatus.downloadingTasksSet -= 1
			return false
		}
		let response = Network.download(url, path: path, overwrite: true)
		convertToALAC(path: path)
		metadata.setMetadata(for: track, at: path)
		downloadStatus.downloadingTasksSet -= 1
		return response.ok
	}
	
	public func download(tracks: [Track], parentFolder: String = "") -> DownloadErrors {
		downloadStatus.downloadingTasksSet += 1
		var errors = DownloadErrors()
		for track in tracks {
			let r = download(track: track, parentFolder: parentFolder)
			if !r {
				errors.affectedTracks.insert(track)
			}
		}
		downloadStatus.downloadingTasksSet -= 1
		return errors
	}
	
	public func download(video: Video, parentFolder: String = "") -> Bool {
		guard let url = video.getVideoUrl(session: session) else { return false }
		print("Downloading Video \(video.title)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: formFileName(video))
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path, overwrite: true)
//		metadataHandler.setMetadata(for: video, at: path)
		// TODO: Metadata for Videos
		return response.ok
	}
	
	public func download(album: Album, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.downloadingTasksSet += 1
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			downloadStatus.downloadingTasksSet -= 1
			return DownloadErrors(affectedAlbums: [album])
		}
		downloadStatus.downloadingTasksSet -= 1
		return download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(album.title)")
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.downloadingTasksSet += 1
		guard let albums = session.getArtistAlbums(artistId: artist.id) else {
			downloadStatus.downloadingTasksSet -= 1
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for album in albums {
			let r = download(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		downloadStatus.downloadingTasksSet -= 1
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.downloadingTasksSet += 1
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		let errors = download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
		downloadStatus.downloadingTasksSet -= 1
		return errors
	}
}

public enum DownloadLocation {
	case downloads
	case music
}

func buildPath(baseLocation: DownloadLocation, parentFolder: String, name: String) -> URL? {
	
//	if !parentFolder.isEmpty {
//		if URL(string: parentFolder) == nil {
//			displayError(title: "Download Error", content: "Target Path '\(targetPath)' is not valid")
//			return nil
//		}
//	}
//	if URL(string: name) == nil {
//		displayError(title: "Download Error", content: "Name '\(name)' is not valid")
//		return nil
//	}
	// TODO: Doesn't work as intended, because URL doesn't allow whitespace, but should
	
	var path: URL
	do {
		switch baseLocation {
		case .downloads:
			path = try FileManager.default.url(for: .downloadsDirectory,
											   in: .userDomainMask,
											   appropriateFor: nil,
											   create: false)
		case .music:
			path = try FileManager.default.url(for: .musicDirectory,
											   in: .userDomainMask,
											   appropriateFor: nil,
											   create: false)
		}
		path.appendPathComponent(parentFolder)
		path.appendPathComponent(name.replacingOccurrences(of: "/", with: ":"))
	} catch {
		displayError(title: "Path Building Error", content: "File Error: \(error)")
		return nil
	}
	return path
}

func convertToALAC(path: URL) {
	
	let tempPathString = path.deletingPathExtension().relativeString + "-temp." + path.pathExtension
	let optionalTempPath = URL(string: tempPathString)
	
	guard let tempPath = optionalTempPath else {
		displayError(title: "ALAC: Error creating path for temporary file", content: "Path: \(tempPathString)")
		return
	}
	
	do {
		if FileManager.default.fileExists(atPath: tempPath.relativeString) {
			try FileManager.default.removeItem(at: tempPath)
		}
		try FileManager.default.moveItem(at: path, to: tempPath)
	} catch {
		displayError(title: "ALAC: Error creating temporary file", content: "Error: \(error)")
	}
	
	let avAsset = AVAsset(url: tempPath)
	let optionalEncoder = SDAVAssetExportSession(asset: avAsset)
	guard let encoder = optionalEncoder else {
		displayError(title: "ALAC: Couldn't create Export Session", content: "Path: \(path)")
		return
	}
	encoder.outputFileType = AVFileType.m4a.rawValue
	encoder.outputURL = path
	encoder.audioSettings = [AVFormatIDKey: kAudioFormatAppleLossless,
							 AVEncoderBitDepthHintKey: 16,
							 AVSampleRateKey: 44100,
							 AVNumberOfChannelsKey: 2]
	
	let semaphore = DispatchSemaphore(value: 0)
	encoder.exportAsynchronously {
		semaphore.signal()
	}
	_ = semaphore.wait(timeout: DispatchTime.distantFuture)
	
	do {
		try FileManager.default.removeItem(at: tempPath)
	} catch {
		displayError(title: "ALAC: Error deleting temporary file after conversion", content: "Error: \(error)")
	}
}

// MARK: - Offline

public class OfflineDB {
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
//		print("Offline: Add Track \(track.id) - \(track.title)")
		if let counter = db.tracks[track] {
			db.tracks[track] = counter + 1
//			print("Offline: Track \(track.title) already exists. Counter: \(db.tracks[track] ?? 0)")
			return true
		}
		
		guard let url = track.getAudioUrl(session: session) else {
			return false
		}
		let optionalPath = buildPath(baseLocation: .music, parentFolder: mainPath, name: "\(track.id).m4a")
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path)
		if response.ok {
			db.tracks[track] = 1
//			print("Offline: Add Track \(track.title) successful. Counter: \(db.tracks[track] ?? 0)")
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
		downloadStatus.downloadingTasksSet += 1
		var result = true
		for track in tracks {
			let r = add(track: track)
			result = result || r
		}
		downloadStatus.downloadingTasksSet -= 1
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
	}
	
	// MARK: - Favorite Tracks
	
	public func syncFavoriteTracks() {
		downloadStatus.downloadingTasksSet += 1
		var tracks: [Track] = []
		if saveFavoritesOffline {
			if let favTracks = session.favorites?.tracks() {
				tracks = favTracks.map { $0.item }
			} else {
				displayError(title: "Error while synchronizing Favorite Tracks", content: "")
				downloadStatus.downloadingTasksSet -= 1
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
		downloadStatus.downloadingTasksSet -= 1
	}
	
	// MARK: - Album
	
	public func isAlbumOffline(album: Album) -> Bool {
		return db.albums.contains(album)
	}
	
	public func add(album: Album) -> Bool {
		downloadStatus.downloadingTasksSet += 1
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			downloadStatus.downloadingTasksSet -= 1
			return false
		}
		db.albums.append(album)
		downloadStatus.downloadingTasksSet -= 1
		return add(tracks: tracks)
	}
	
	public func remove(album: Album) {
		if let tracks = session.getAlbumTracks(albumId: album.id) {
			remove(tracks: tracks)
			db.albums.removeAll(where: { $0 == album })
		}
	}
	
	// MARK: - Playlist
	
	public func isPlaylistOffline(playlist: Playlist) -> Bool {
		db.playlists.contains(playlist)
	}
	
	public func syncPlaylist(_ playlist: Playlist) {
		var tracks: [Track] = []
		let dbTracks: [Track] = db.playlistTracks[playlist] ?? []
		let syncThisPlaylist: Bool = db.playlists.contains(playlist)
		
		if syncThisPlaylist {
			downloadStatus.downloadingTasksSet += 1
			if let playlistTracks = session.getPlaylistTracks(playlistId: playlist.id) {
				tracks = playlistTracks
			} else {
				displayError(title: "Error while synchronizing Playlist Tracks", content: "Couldn't load playlist tracks from Tidal API.")
				downloadStatus.downloadingTasksSet -= 1
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
			downloadStatus.downloadingTasksSet -= 1
		}
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
