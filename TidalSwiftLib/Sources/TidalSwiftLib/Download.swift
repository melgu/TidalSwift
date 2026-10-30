//
//  Download.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import Observation
import OSLog

private let logger = Logger(category: "Download")

@Observable
public final class DownloadStatus {
	public private(set) var tasks: [DownloadTask] = []
	
	public func startTask(title: String) -> DownloadTask {
		let task = DownloadTask(title: title)
		tasks.append(task)
		return task
	}
	
	public func finishTask(_ task: DownloadTask) {
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
		
		public init(title: String, index: Int, count: Int) {
			self.title = title
			self.index = index
			self.count = count
		}
	}
	
	public let title: String
	/// Only set for downloads spanning several albums
	public var album: Step?
	public var track: Step?
	public var video: Step?
	/// How much of the current video is downloaded, as tracks are quick enough without
	public var progress: Double?
	
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

public struct DownloadOptions {
	public var audioQuality: AudioQuality
	/// Downloads Dolby Atmos instead of stereo for tracks that have both
	public var preferDolbyAtmos: Bool
	/// Folder downloads are put in. Albums, artists and playlists get a subfolder.
	public var destination: URL
	
	public init(audioQuality: AudioQuality, preferDolbyAtmos: Bool, destination: URL) {
		self.audioQuality = audioQuality
		self.preferDolbyAtmos = preferDolbyAtmos
		self.destination = destination
	}
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
	
	/// Path of a file within the destination, with slashes in names replaced, as they would create folders
	private func path(in destination: URL, parentFolder: String, name: String, pathExtension: String) -> URL {
		var path = destination
		if !parentFolder.isEmpty {
			path.appendPathComponent(parentFolder)
		}
		path.appendPathComponent(name.replacingOccurrences(of: "/", with: ":"))
		return path.appendingPathExtension(pathExtension)
	}
	
	public func download(track: Track, parentFolder: String = "", options: DownloadOptions) async -> Bool {
		let task = downloadStatus.startTask(title: "\(track.title) – \(track.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		return await downloadTrack(track, parentFolder: parentFolder, options: options)
	}
	
	private func downloadTrack(_ track: Track, parentFolder: String, options: DownloadOptions) async -> Bool {
		guard let stream = await track.audioStream(session: session, audioQuality: options.audioQuality, preferDolbyAtmos: options.preferDolbyAtmos) else {
			return false
		}
		let filename = formFileName(track)
		logger.debug("Downloading: \(filename)")
		let path = path(in: options.destination, parentFolder: parentFolder, name: filename, pathExtension: stream.pathExtension)
		
		do {
			try await Network.download(stream.url, path: path, overwrite: true)
		} catch {
			displayError(title: "Error while downloading track", content: "Download failed for track \(track.title). Error: \(error)")
			return false
		}
		
		await metadata.setMetadata(for: track, at: path)
		logger.debug("Download Finished: \(filename)")
		return true
	}
	
	public func download(tracks: [Track], parentFolder: String = "", options: DownloadOptions) async -> DownloadErrors {
		let task = downloadStatus.startTask(title: parentFolder.isEmpty ? "\(tracks.count) Tracks" : parentFolder)
		defer { downloadStatus.finishTask(task) }
		
		return await downloadTracks(tracks, parentFolder: parentFolder, options: options, task: task)
	}
	
	private func downloadTracks(_ tracks: [Track], parentFolder: String, options: DownloadOptions, task: DownloadTask) async -> DownloadErrors {
		defer { task.track = nil }
		
		var errors = DownloadErrors()
		for (index, track) in tracks.enumerated() {
			task.track = DownloadTask.Step(title: track.title, index: index + 1, count: tracks.count)
			let success = await downloadTrack(track, parentFolder: parentFolder, options: options)
			if !success {
				errors.affectedTracks.insert(track)
			}
		}
		logger.debug("Track Download Done!")
		return errors
	}
	
	/// Only uses the destination of the options, as videos come in a single quality
	public func download(video: Video, parentFolder: String = "", options: DownloadOptions) async -> Bool {
		let task = downloadStatus.startTask(title: "\(video.title) – \(video.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		guard let url = await video.videoUrl(session: session) else {
			displayError(title: "Error while downloading video", content: "Couldn't get Video URL for \(video.title)")
			return false
		}
		let filename = formFileName(video)
		logger.debug("Downloading Video: \(filename)")
		let path = path(in: options.destination, parentFolder: parentFolder, name: filename, pathExtension: "mp4")
		
		let tags = await metadata.tags(for: video)
		do {
			try await HLSDownloader.download(url, to: path, tags: tags) { progress in
				task.progress = progress
			}
		} catch {
			displayError(title: "Error while downloading video", content: "Download failed for video \(video.title). Error: \(error)")
			return false
		}
		logger.debug("Download Finished: \(filename)")
		return true
	}
	
	public func download(album: Album, parentFolder: String = "", options: DownloadOptions) async -> DownloadErrors {
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		let task = downloadStatus.startTask(title: "\(artistString)\(album.title)")
		defer { downloadStatus.finishTask(task) }
		
		return await downloadAlbum(album, parentFolder: parentFolder, options: options, task: task)
	}
	
	private func downloadAlbum(_ album: Album, parentFolder: String, options: DownloadOptions, task: DownloadTask) async -> DownloadErrors {
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return DownloadErrors(affectedAlbums: [album])
		}
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		return await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artistString)\(album.title.replacingOccurrences(of: "/", with: ":"))", options: options, task: task)
	}
	
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "", options: DownloadOptions) async -> DownloadErrors {
		let task = downloadStatus.startTask(title: artist.name)
		defer { downloadStatus.finishTask(task) }
		
		guard let albums = await session.artistAlbums(artistId: artist.id) else {
			return DownloadErrors(affectedArtists: [artist])
		}
		var error = DownloadErrors()
		for (index, album) in albums.enumerated() {
			task.album = DownloadTask.Step(title: album.title, index: index + 1, count: albums.count)
			let r = await downloadAlbum(album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)", options: options, task: task)
			error.affectedAlbums.formUnion(r.affectedAlbums)
			error.affectedTracks.formUnion(r.affectedTracks)
		}
		return error
	}
	
	public func download(playlist: Playlist, parentFolder: String = "", options: DownloadOptions) async -> DownloadErrors {
		let task = downloadStatus.startTask(title: playlist.title)
		defer { downloadStatus.finishTask(task) }
		
		guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
			return DownloadErrors(affectedPlaylists: [playlist])
		}
		let errors = await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)", options: options, task: task)
		return errors
	}
}
