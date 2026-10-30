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

public enum DownloadError: LocalizedError {
	/// Tidal didn't provide a stream, e.g. because the item isn't available in the account's country
	case streamUnavailable
	/// The tracks or albums to download couldn't be loaded
	case contentsUnavailable
	/// Downloading or writing the file failed
	case transfer(underlying: Error)
	
	public var errorDescription: String? {
		switch self {
		case .streamUnavailable:
			"No stream available"
		case .contentsUnavailable:
			"Couldn't load the contents"
		case .transfer(let underlying):
			"Download failed: \(underlying.localizedDescription)"
		}
	}
}

/// Outcome of downloading several tracks, which continues past failed ones
public struct DownloadResult {
	public enum Item {
		case track(Track)
		case album(Album)
		case artist(Artist)
		case playlist(Playlist)
	}
	
	public struct Failure {
		public let item: Item
		public let error: DownloadError
	}
	
	public fileprivate(set) var downloadedTracks = 0
	public fileprivate(set) var failures: [Failure] = []
	
	fileprivate mutating func append(_ other: DownloadResult) {
		downloadedTracks += other.downloadedTracks
		failures += other.failures
	}
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
	
	/// Returns the downloaded file
	@discardableResult
	public func download(track: Track, parentFolder: String = "", options: DownloadOptions) async throws(DownloadError) -> URL {
		let task = downloadStatus.startTask(title: "\(track.title) – \(track.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		return try await downloadTrack(track, parentFolder: parentFolder, options: options)
	}
	
	private func downloadTrack(_ track: Track, parentFolder: String, options: DownloadOptions) async throws(DownloadError) -> URL {
		guard let stream = await track.audioStream(session: session, audioQuality: options.audioQuality, preferDolbyAtmos: options.preferDolbyAtmos) else {
			displayError(title: "Error while downloading track", content: "No stream for track \(track.title)")
			throw .streamUnavailable
		}
		let filename = formFileName(track)
		logger.debug("Downloading: \(filename)")
		let path = path(in: options.destination, parentFolder: parentFolder, name: filename, pathExtension: stream.pathExtension)
		
		do {
			try await Network.download(stream.url, path: path, overwrite: true)
		} catch {
			displayError(title: "Error while downloading track", content: "Download failed for track \(track.title). Error: \(error)")
			throw .transfer(underlying: error)
		}
		
		await metadata.setMetadata(for: track, at: path)
		logger.debug("Download Finished: \(filename)")
		return path
	}
	
	@discardableResult
	public func download(tracks: [Track], parentFolder: String = "", options: DownloadOptions) async -> DownloadResult {
		let task = downloadStatus.startTask(title: parentFolder.isEmpty ? "\(tracks.count) Tracks" : parentFolder)
		defer { downloadStatus.finishTask(task) }
		
		return await downloadTracks(tracks, parentFolder: parentFolder, options: options, task: task)
	}
	
	private func downloadTracks(_ tracks: [Track], parentFolder: String, options: DownloadOptions, task: DownloadTask) async -> DownloadResult {
		defer { task.track = nil }
		
		var result = DownloadResult()
		for (index, track) in tracks.enumerated() {
			task.track = DownloadTask.Step(title: track.title, index: index + 1, count: tracks.count)
			do {
				_ = try await downloadTrack(track, parentFolder: parentFolder, options: options)
				result.downloadedTracks += 1
			} catch {
				result.failures.append(DownloadResult.Failure(item: .track(track), error: error))
			}
		}
		logger.debug("Track Download Done!")
		return result
	}
	
	/// Only uses the destination of the options, as videos come in a single quality. Returns the downloaded file.
	@discardableResult
	public func download(video: Video, parentFolder: String = "", options: DownloadOptions) async throws(DownloadError) -> URL {
		let task = downloadStatus.startTask(title: "\(video.title) – \(video.artists.formArtistString())")
		defer { downloadStatus.finishTask(task) }
		
		guard let url = await video.videoUrl(session: session) else {
			displayError(title: "Error while downloading video", content: "Couldn't get Video URL for \(video.title)")
			throw .streamUnavailable
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
			throw .transfer(underlying: error)
		}
		logger.debug("Download Finished: \(filename)")
		return path
	}
	
	@discardableResult
	public func download(album: Album, parentFolder: String = "", options: DownloadOptions) async -> DownloadResult {
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		let task = downloadStatus.startTask(title: "\(artistString)\(album.title)")
		defer { downloadStatus.finishTask(task) }
		
		return await downloadAlbum(album, parentFolder: parentFolder, options: options, task: task)
	}
	
	private func downloadAlbum(_ album: Album, parentFolder: String, options: DownloadOptions, task: DownloadTask) async -> DownloadResult {
		guard let tracks = await session.albumTracks(albumId: album.id) else {
			return DownloadResult(failures: [DownloadResult.Failure(item: .album(album), error: .contentsUnavailable)])
		}
		let artistString = album.artists != nil ? "\(album.artists!.formArtistString()) - " : ""
		return await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artistString)\(album.title.replacingOccurrences(of: "/", with: ":"))", options: options, task: task)
	}
	
	@discardableResult
	public func downloadAllAlbums(from artist: Artist, parentFolder: String = "", options: DownloadOptions) async -> DownloadResult {
		let task = downloadStatus.startTask(title: artist.name)
		defer { downloadStatus.finishTask(task) }
		
		guard let albums = await session.artistAlbums(artistId: artist.id) else {
			return DownloadResult(failures: [DownloadResult.Failure(item: .artist(artist), error: .contentsUnavailable)])
		}
		var result = DownloadResult()
		for (index, album) in albums.enumerated() {
			task.album = DownloadTask.Step(title: album.title, index: index + 1, count: albums.count)
			result.append(await downloadAlbum(album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)", options: options, task: task))
		}
		return result
	}
	
	@discardableResult
	public func download(playlist: Playlist, parentFolder: String = "", options: DownloadOptions) async -> DownloadResult {
		let task = downloadStatus.startTask(title: playlist.title)
		defer { downloadStatus.finishTask(task) }
		
		guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
			return DownloadResult(failures: [DownloadResult.Failure(item: .playlist(playlist), error: .contentsUnavailable)])
		}
		return await downloadTracks(tracks, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)", options: options, task: task)
	}
}
