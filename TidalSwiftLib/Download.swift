//
//  Download.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SDAVAssetExportSession

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
	
	public func download(track: Track, parentFolder: String = "", audioQuality: AudioQuality) -> Bool {
		downloadStatus.startTask()
		guard let url = track.getAudioUrl(session: session, audioQuality: audioQuality) else {
			downloadStatus.finishTask()
			return false
		}
		let filename = formFileName(track)
		print("Downloading: \(filename)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: filename, pathExtension: session.pathExtension(for: audioQuality))
		guard var path = optionalPath else {
			displayError(title: "Error while downloading track", content: "Couldn't build path for track: \(track.title) -  \(track.artists.formArtistString())")
			downloadStatus.finishTask()
			return false
		}
		
		var response: Response!
		repeat {
			response = Network.download(url, path: path, overwrite: true)
		} while response.statusCode == 1001
		
		if audioQuality == .hifi || audioQuality == .master {
			// Has to be done, as Tidal sometimes serves the files in a strange QuickTime container (qt), which doesn't support metadata tags.
			// Or it's just flac and therefore doesn't work.
			convertToALAC(path: path)
			path.deletePathExtension()
			path.appendPathExtension("m4a")
		}
		
		metadata.setMetadata(for: track, at: path)
		print("Download Finished: \(filename)")
		downloadStatus.finishTask()
		return response.ok
	}
	
	public func download(tracks: [Track], parentFolder: String = "") -> DownloadErrors {
		downloadStatus.startTask()
		let group = DispatchGroup()
		let semaphore = DispatchSemaphore(value: 1)
		var errors = DownloadErrors()
		for track in tracks {
			group.enter()
			dispatchQueue.async { [self] in
				let r = download(track: track, parentFolder: parentFolder, audioQuality: session.config.offlineAudioQuality)
				if !r {
					semaphore.wait()
					errors.affectedTracks.insert(track)
					semaphore.signal()
				}
				group.leave()
			}
		}
		group.wait()
		print("Track Download Done!")
		downloadStatus.finishTask()
		return errors
	}
	
	public func download(video: Video, parentFolder: String = "") -> Bool {
		guard let url = video.getVideoUrl(session: session) else { return false }
		print("Downloading Video \(video.title)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: formFileName(video), pathExtension: "mp4")
		guard let path = optionalPath else {
			return false
		}
		let response = Network.download(url, path: path, overwrite: true)
//		metadataHandler.setMetadata(for: video, at: path)
		// TODO: Metadata for Videos
		return response.ok
	}
	
	public func download(album: Album, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.startTask()
		guard let tracks = session.getAlbumTracks(albumId: album.id) else {
			downloadStatus.finishTask()
			return DownloadErrors(affectedAlbums: [album])
		}
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		let r = download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artistString)\(album.title.replacingOccurrences(of: "/", with: ":"))")
		downloadStatus.finishTask()
		return r
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.startTask()
		guard let albums = session.getArtistAlbums(artistId: artist.id) else {
			downloadStatus.finishTask()
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for album in albums {
			let r = download(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		downloadStatus.finishTask()
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "") -> DownloadErrors {
		downloadStatus.startTask()
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		let errors = download(tracks: tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
		downloadStatus.finishTask()
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
	guard let encoder = SDAVAssetExportSession(asset: avAsset) else {
		displayError(title: "ALAC: Couldn't create Export Session", content: "Path: \(path)")
		return
	}
	encoder.outputFileType = AVFileType.m4a.rawValue
	encoder.outputURL = path.deletingPathExtension().appendingPathExtension("m4a")
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
