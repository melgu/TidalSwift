//
//  Download.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import AVFoundation
import Observation

@Observable
public final class DownloadStatus {
	public private(set) var tasks: [DownloadTask] = []
	
	func startTask(title: String) -> DownloadTask {
		let task = DownloadTask(title: title)
		tasks.append(task)
		return task
	}
	
	func finishTask(_ task: DownloadTask) {
		tasks.removeAll { $0 === task }
	}
}

@Observable
public final class DownloadTask: Identifiable {
	/// Position of the item being worked on within its parent, e.g. the third of twelve tracks
	public struct Step {
		public let title: String
		public let index: Int
		public let count: Int
	}
	
	public let title: String
	/// Only set for downloads spanning several albums
	public internal(set) var album: Step?
	public internal(set) var track: Step?
	public internal(set) var video: Step?
	/// How much of the current video is downloaded, as tracks are quick enough without
	public internal(set) var progress: Double?
	
	init(title: String) {
		self.title = title
	}
}

public struct DownloadErrors {
	fileprivate var affectedTracks = Set<Track>()
	fileprivate var affectedAlbums = Set<Album>()
	fileprivate var affectedArtists = Set<Artist>()
	fileprivate var affectedPlaylists = Set<Playlist>()
}

public enum DownloadLocation {
	case downloads
	case music
}

public class Download {
	private unowned let session: Session
	private unowned let metadata: Metadata
	private let downloadStatus: DownloadStatus
	
	init(session: Session, metadata: Metadata, downloadStatus: DownloadStatus) {
		self.session = session
		self.metadata = metadata
		self.downloadStatus = downloadStatus
	}
	
	private func formFileName(_ track: Track) -> String {
		var title = track.title
		if let version = track.version {
			title += " (\(version))"
		}
		return "\(track.trackNumber) \(title) - \(track.artists.formArtistString())"
	}
	
	private func formFileName(_ video: Video) -> String {
		"\(video.trackNumber) \(video.title) - \(video.artists.formArtistString())"
	}
	
	/// Uses the offline audio quality and Dolby Atmos preference
	public func download(track: Track, parentFolder: String = "") async -> Bool {
		let task = downloadStatus.startTask(title: "\(track.title) – \(track.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		return await downloadTrack(track, parentFolder: parentFolder)
	}
	
	private func downloadTrack(_ track: Track, parentFolder: String) async -> Bool {
		guard let stream = await track.audioStream(session: session, audioQuality: session.config.offlineAudioQuality, preferDolbyAtmos: session.helpers.offline.preferDolbyAtmos) else {
			return false
		}
		let filename = formFileName(track)
		print("Downloading: \(filename)")
		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: filename, pathExtension: stream.pathExtension)
		guard let path = optionalPath else {
			displayError(title: "Error while downloading track", content: "Couldn't build path for track: \(track.title) -  \(track.artists.formArtistString())")
			return false
		}
		
		do {
			try await Network.download(stream.url, path: path, overwrite: true)
		} catch {
			displayError(title: "Error while downloading track", content: "Download failed for track \(track.title). Error: \(error)")
			return false
		}
		
		await metadata.setMetadata(for: track, at: path)
		print("Download Finished: \(filename)")
		return true
	}
	
	public func download(tracks: [Track], parentFolder: String = "") async -> DownloadErrors {
		let task = downloadStatus.startTask(title: parentFolder.isEmpty ? "\(tracks.count) Tracks" : parentFolder)
		defer { downloadStatus.finishTask(task) }
		
		return await downloadTracks(tracks, parentFolder: parentFolder, task: task)
	}
	
	private func downloadTracks(_ tracks: [Track], parentFolder: String, task: DownloadTask) async -> DownloadErrors {
		defer { task.track = nil }
		
		var errors = DownloadErrors()
		for (index, track) in tracks.enumerated() {
			task.track = DownloadTask.Step(title: track.title, index: index + 1, count: tracks.count)
			let success = await downloadTrack(track, parentFolder: parentFolder)
			if !success {
				errors.affectedTracks.insert(track)
			}
		}
		print("Track Download Done!")
		return errors
	}
	
	public func download(video: Video, parentFolder: String = "") async -> Bool {
		let task = downloadStatus.startTask(title: "\(video.title) – \(video.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		guard let url = await video.videoUrl(session: session) else {
			displayError(title: "Error while downloading video", content: "Couldn't get Video URL for \(video.title)")
			return false
		}
		let filename = formFileName(video)
		print("Downloading Video: \(filename)")
		guard let path = buildPath(baseLocation: .downloads, parentFolder: parentFolder, name: filename, pathExtension: "mp4") else {
			displayError(title: "Error while downloading video", content: "Couldn't build path for video: \(video.title) - \(video.artists.formArtistString())")
			return false
		}
		
		let tags = await metadata.tags(for: video)
		do {
			try await HLSDownloader.download(url, to: path, tags: tags) { progress in
				task.progress = progress
			}
		} catch {
			displayError(title: "Error while downloading video", content: "Download failed for video \(video.title). Error: \(error)")
			return false
		}
		print("Download Finished: \(filename)")
		return true
	}
	
	public func download(album: Album, parentFolder: String = "") async -> DownloadErrors {
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		let task = downloadStatus.startTask(title: "\(artistString)\(album.title)")
		defer { downloadStatus.finishTask(task) }
		
		return await downloadAlbum(album, parentFolder: parentFolder, task: task)
	}
	
	private func downloadAlbum(_ album: Album, parentFolder: String, task: DownloadTask) async -> DownloadErrors {
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return DownloadErrors(affectedAlbums: [album])
		}
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		return await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artistString)\(album.title.replacingOccurrences(of: "/", with: ":"))", task: task)
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "") async -> DownloadErrors {
		let task = downloadStatus.startTask(title: artist.name)
		defer { downloadStatus.finishTask(task) }
		
		guard let albums = await session.artistAlbums(artistId: artist.id) else {
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for (index, album) in albums.enumerated() {
			task.album = DownloadTask.Step(title: album.title, index: index + 1, count: albums.count)
			let r = await downloadAlbum(album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)", task: task)
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "") async -> DownloadErrors {
		let task = downloadStatus.startTask(title: playlist.title)
		defer { downloadStatus.finishTask(task) }
		
		guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		let errors = await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)", task: task)
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
