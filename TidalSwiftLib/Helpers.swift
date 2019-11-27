//
//  Helpers.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SDAVAssetExportSession

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
	let metadata: Metadata
	
	public init(session: Session) {
		self.session = session
		self.offline = Offline(session: session)
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
		guard let url = track.getAudioUrl(session: session) else { return false }
		print("Downloading \(track.title)")
		let fileName = formFileName(track)
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: fileName)
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path, overwrite: true)
		convertToALAC(path: path)
		metadata.setMetadata(for: track, at: path)
		return response.ok
	}
	
	public func download(tracks: [Track], parentFolder: String = "") -> DownloadErrors {
		var errors = DownloadErrors()
		for track in tracks {
			let r = download(track: track, parentFolder: parentFolder)
			if !r {
				errors.affectedTracks.insert(track)
			}
		}
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
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			return DownloadErrors(affectedAlbums: [album])
		}
		return download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(album.title)")
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "") -> DownloadErrors {
		guard let albums = session.getArtistAlbums(artistId: artist.id) else {
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for album in albums {
			let r = download(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "") -> DownloadErrors {
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		return download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
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

// TODO: Database to keep track which files are needed multiple times
// Abstract that from the library user.
public class Offline {
	unowned let session: Session
	let mainPath = "TidalSwift Offline Library"
	
	// [Track: ByHowManyNeeded]
	var db: [Track: Int] = [:] {
		didSet {
			saveDB()
		}
	}
	
	public init(session: Session) {
		self.session = session
		
		// Create main folder if it doesn't exist
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		} catch {
			displayError(title: "Error while creating Offline management class", content: "Error: \(error)")
		}
		if let data = UserDefaults.standard.data(forKey: "OfflineDB") {
			if let tempDB = try? JSONDecoder().decode([Track: Int].self, from: data) {
				self.db = tempDB
			} else {
				self.db = [:]
			}
		}
	}
	
	public func saveDB() {
		let data = try? JSONEncoder().encode(db)
		UserDefaults.standard.set(data, forKey: "OfflineDB")
		UserDefaults.standard.synchronize()
	}
	
	public func numberOfOfflineTracks() -> Int {
		return db.count
	}
	
	public func allOfflineTracks() -> [Track]? {
		return db.map { (track, _) in track }
	}
	
	public var offlineDB: [Track: Int] { return db }
	
	// MARK: - Single Track
	
	public func isTrackOffline(track: Track) -> Bool {
		return db[track] != nil
	}
	
	public func add(track: Track) -> Bool {
		print("Offline: Add Track \(track.id) - \(track.title)")
		if let counter = db[track] {
			db[track] = counter + 1
			print("Offline: Track \(track.title) already exists. Counter: \(db[track] ?? 0)")
			return true
		}
		
		guard let url = track.getAudioUrl(session: session) else {
			return false
		}
		let optionalPath = buildPath(baseLocation: .music, parentFolder: mainPath, name: String(track.id))
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path)
		if response.ok {
			db[track] = 1
			print("Offline: Add Track \(track.title) successful. Counter: \(db[track] ?? 0)")
		}
		return response.ok
	}
	
	public func remove(track: Track) {
		print("Offline: Remove Track \(track.id) - \(track.title). Counter: \(db[track] ?? 0)")
		if let counter = db[track] {
			if counter <= 1 { // Would be 0 after decrement
				print("Offline: \(track.title). Counter 0, deleting.")
				db.removeValue(forKey: track)
				// Remove from db instead of setting 0 to save space and allow simpler counting
			} else {
				db[track] = counter - 1
				print("Offline: \(track.title). Counter above 0, so not removing. New counter \(db[track] ?? 0)")
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
			path.appendPathComponent(String(track.id))
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
	public func add(tracks: [Track]) -> Bool {
		var result = false
		for track in tracks {
			let r = add(track: track)
			result = result || r
		}
		return result
	}
	
	public func remove(tracks: [Track]) {
		for track in tracks {
			remove(track: track)
		}
	}
	
	public func removeAll() {
		print("Removing all \(db.count) offline tracks")
		db = [:]
		
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
	}
	
	// MARK: - Album
	
	public func isAlbumOffline(album: Album) -> Bool? {
		if let tracks = session.getAlbumTracks(albumId: album.id) {
			return areTracksOffline(tracks: tracks)
		} else {
			return nil
		}
	}
	
	public func add(album: Album) -> Bool {
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			return false
		}
		return add(tracks: tracks)
	}
	
	public func remove(album: Album) {
		if let tracks = session.getAlbumTracks(albumId: album.id) {
			return remove(tracks: tracks)
		}
	}
	
	// MARK: - Playlist
	
	public func isPlaylistOffline(playlist: Playlist) -> Bool? {
		if let tracks = session.getPlaylistTracks(playlistId: playlist.id) {
			return areTracksOffline(tracks: tracks)
		} else {
			return nil
		}
	}
	
	public func add(playlist: Playlist) -> Bool {
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.id) else {
			return false
		}
		return add(tracks: tracks)
	}
	
	public func remove(playlist: Playlist) {
		if let tracks = session.getPlaylistTracks(playlistId: playlist.id) {
			return remove(tracks: tracks)
		}
	}
}
