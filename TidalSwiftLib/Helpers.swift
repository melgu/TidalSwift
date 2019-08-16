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
	var affectedTracks = [Track]()
	var affectedAlbums = [Album]()
	var affectedArtists = [Artist]()
	var affectedPlaylists = [Playlist]()
}

public class Helpers {
	unowned let session: Session
	let offline: Offline
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
	
	public func downloadTrack(track: Track, parentFolder: String = "") -> Bool {
		guard let url = session.getAudioUrl(trackId: track.id) else { return false }
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
	
	public func downloadVideo(video: Video, parentFolder: String = "") -> Bool {
		guard let url = session.getVideoUrl(videoId: video.id) else { return false }
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: formFileName(video))
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path, overwrite: true)
//		metadataHandler.setMetadata(for: video, at: path)
		// TODO: Metadata for Videos
		return response.ok
	}
	
	public func downloadAlbum(album: Album, parentFolder: String = "") -> DownloadErrors {
		guard let tracks = session.getAlbumTracks(albumId: album.id) else { return DownloadErrors(affectedAlbums: [album]) }
		var error = DownloadErrors()
		for track in tracks {
			let r = downloadTrack(track: track, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(album.title)")
			if !r {
				error.affectedTracks.append(track)
			}
		}
		return error
	}
	
	public func downloadAllAlbumsFromArtist(artist: Artist, parentFolder: String = "") -> DownloadErrors {
		guard let albums = session.getArtistAlbums(artistId: artist.id) else {
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for album in albums {
			let r = downloadAlbum(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.append(contentsOf: r.affectedAlbums)
			error.affectedTracks.append(contentsOf: r.affectedTracks)
		}
		return error
	}
	
	public func downloadPlaylist(playlist: Playlist, parentFolder: String = "") -> DownloadErrors {
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		var error = DownloadErrors()
		for track in tracks {
			let r = downloadTrack(track: track,
								  parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
			if !r {
				error.affectedTracks.append(track)
			}
		}
		return error
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
		path.appendPathComponent(name)
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
	}
	
	public func addTrack(trackId: Int) -> Bool {
		guard let url = session.getAudioUrl(trackId: trackId) else {
			return false
		}
		let optionalPath = buildPath(baseLocation: .music, parentFolder: mainPath, name: String(trackId))
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path)
		return response.ok
	}
	
	// Warning: Does not check if song is still needed present in other offline album, playlist or other
	public func removeTrack(trackId: Int) {
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			path.appendPathComponent(String(trackId))
			if FileManager.default.fileExists(atPath: path.relativePath) {
				try FileManager.default.removeItem(at: path)
			}
		} catch {
			displayError(title: "Error while removing Offline track", content: "Error: \(error)")
		}
	}

}
