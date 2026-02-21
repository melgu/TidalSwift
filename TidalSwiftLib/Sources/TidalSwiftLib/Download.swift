//
//  Download.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import AVFoundation

public final class DownloadStatus: ObservableObject {
	@Published public var downloadingTasks: Int = 0
	
	func startTask() {
		DispatchQueue.main.async { [weak self] in
			self?.downloadingTasks += 1
		}
	}
	
	func finishTask() {
		DispatchQueue.main.async { [weak self] in
			self?.downloadingTasks -= 1
		}
	}
}

public struct DownloadErrors {
	var affectedTracks = Set<Track>()
	var affectedAlbums = Set<Album>()
	var affectedArtists = Set<Artist>()
	var affectedPlaylists = Set<Playlist>()
}

public enum DownloadLocation {
	case downloads
	case music
}

public class Download {
	unowned let session: Session
	unowned let metadata: Metadata
	private let downloadStatus: DownloadStatus
	
	
	private var dispatchQueue = DispatchQueue(label: "melgu.TidalSwift.download", qos: .background)
	
	init(session: Session, metadata: Metadata, downloadStatus: DownloadStatus) {
		self.session = session
		self.metadata = metadata
		self.downloadStatus = downloadStatus
	}
	
	func formFileName(_ track: Track) -> String {
		var title = track.title
		if let version = track.version {
			title += " (\(version))"
		}
		return "\(track.trackNumber) \(title) - \(track.artists.formArtistString())"
	}
	
	func formFileName(_ video: Video) -> String {
		"\(video.trackNumber) \(video.title) - \(video.artists.formArtistString())"
	}
	
	public func download(track: Track, parentFolder: String = "", audioQuality: AudioQuality) async -> Bool {
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		guard let url = await track.audioUrl(session: session, audioQuality: audioQuality) else {
			return false
		}
		let filename = formFileName(track)
		print("Downloading: \(filename)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: filename, pathExtension: session.pathExtension(for: audioQuality))
		guard var path = optionalPath else {
			displayError(title: "Error while downloading track", content: "Couldn't build path for track: \(track.title) -  \(track.artists.formArtistString())")
			return false
		}
		
		do {
			try await Network.download(url, path: path, overwrite: true)
		} catch {
			displayError(title: "Error while downloading track", content: "Download failed for track \(track.title). Error: \(error)")
			return false
		}
		
//		await metadata.setMetadata(for: track, at: path)
		print("Download Finished: \(filename)")
		return true
	}
	
	public func download(tracks: [Track], parentFolder: String = "") async -> DownloadErrors {
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		var errors = DownloadErrors()
		for track in tracks {
			let success = await download(track: track, parentFolder: parentFolder, audioQuality: session.config.offlineAudioQuality)
			if !success {
				errors.affectedTracks.insert(track)
			}
		}
		print("Track Download Done!")
		return errors
	}
	
	public func download(video: Video, parentFolder: String = "") async -> Bool {
		guard let url = await video.videoUrl(session: session) else { return false }
		print("Downloading Video \(video.title)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: formFileName(video), pathExtension: "mp4")
		guard let path = optionalPath else {
			return false
		}
		do {
			try await Network.download(url, path: path, overwrite: true)
			return true
		} catch {
			return false
		}
//		metadataHandler.setMetadata(for: video, at: path)
		// TODO: Metadata for Videos
	}
	
	public func download(album: Album, parentFolder: String = "") async -> DownloadErrors {
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return DownloadErrors(affectedAlbums: [album])
		}
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		return await download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artistString)\(album.title.replacingOccurrences(of: "/", with: ":"))")
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "") async -> DownloadErrors {
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		guard let albums = await session.artistAlbums(artistId: artist.id) else {
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for album in albums {
			let r = await download(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "") async -> DownloadErrors {
		downloadStatus.startTask()
		defer { downloadStatus.finishTask() }
		
		guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		let errors = await download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
		return errors
	}
}

func buildPath(baseLocation: DownloadLocation, parentFolder: String?, name: String, pathExtension: String?) -> URL? {
	
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
		if let parentFolder = parentFolder {
			path.appendPathComponent(parentFolder)
		}
		path.appendPathComponent(name.replacingOccurrences(of: "/", with: ":"))
		if let pathExtension = pathExtension {
			path.appendPathExtension(pathExtension)
		}
	} catch {
		displayError(title: "Path Building Error", content: "File Error: \(error)")
		return nil
	}
	return path
}
