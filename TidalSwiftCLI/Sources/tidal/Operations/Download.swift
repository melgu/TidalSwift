//
//  Download.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct DownloadSummary: Codable {
	struct Failure: Codable {
		let kind: ItemKind
		let title: String
		let reason: String
	}
	
	/// Tracks and videos
	let downloadedItems: Int
	let failures: [Failure]
	let destination: String
}

/// The folder at a path, which may start with ~, or the fallback if none is given
func downloadFolder(path: String?, fallback: URL) throws -> URL {
	let folder = path.map { URL(filePath: ($0 as NSString).expandingTildeInPath, directoryHint: .isDirectory) } ?? fallback
	var isDirectory: ObjCBool = false
	guard FileManager.default.fileExists(atPath: folder.path(), isDirectory: &isDirectory), isDirectory.boolValue else {
		throw CLIError("\(folder.path()) isn't a folder")
	}
	return folder
}

/// Downloads into the destination, with a subfolder for albums, artists and playlists.
/// Calls `progress` with the item being worked on.
@MainActor
func download(session: Session, link: TidalLink, options: DownloadOptions, progress: @escaping (String) -> Void) async throws -> DownloadSummary {
	let download = session.helpers.download
	let reporter = Task {
		await reportProgress(of: session.helpers.downloadStatus, to: progress)
	}
	defer { reporter.cancel() }
	
	let result: DownloadResult
	switch link {
	case .track(let id):
		guard let track = await session.track(trackId: id) else {
			throw CLIError("Couldn't load track \(id)")
		}
		do {
			try await download.download(track: track, options: options)
			return DownloadSummary(downloadedItems: 1, failures: [], destination: options.destination.path())
		} catch {
			throw CLIError("Couldn't download \(track.title): \(error.localizedDescription)")
		}
	case .video(let id):
		guard let video = await session.video(videoId: id) else {
			throw CLIError("Couldn't load video \(id)")
		}
		do {
			try await download.download(video: video, options: options)
			return DownloadSummary(downloadedItems: 1, failures: [], destination: options.destination.path())
		} catch {
			throw CLIError("Couldn't download \(video.title): \(error.localizedDescription)")
		}
	case .album(let id):
		guard let album = await session.album(albumId: id) else {
			throw CLIError("Couldn't load album \(id)")
		}
		result = await download.download(album: album, options: options)
	case .artist(let id):
		guard let artist = await session.artist(artistId: id) else {
			throw CLIError("Couldn't load artist \(id)")
		}
		result = await download.downloadAllAlbums(from: artist, options: options)
	case .playlist(let uuid):
		guard let playlist = await session.playlist(playlistId: uuid) else {
			throw CLIError("Couldn't load playlist \(uuid)")
		}
		result = await download.download(playlist: playlist, options: options)
	}
	
	return DownloadSummary(
		downloadedItems: result.downloadedTracks,
		failures: result.failures.map(DownloadSummary.Failure.init),
		destination: options.destination.path()
	)
}

extension DownloadSummary.Failure {
	@MainActor
	init(_ failure: DownloadResult.Failure) {
		let reason = failure.error.localizedDescription
		switch failure.item {
		case .track(let track):
			self.init(kind: .track, title: track.title, reason: reason)
		case .album(let album):
			self.init(kind: .album, title: album.title, reason: reason)
		case .artist(let artist):
			self.init(kind: .artist, title: artist.name, reason: reason)
		case .playlist(let playlist):
			self.init(kind: .playlist, title: playlist.title, reason: reason)
		}
	}
}

/// Reports each step of the running download until cancelled
@MainActor
private func reportProgress(of status: DownloadStatus, to progress: (String) -> Void) async {
	var lastReport: String?
	while !Task.isCancelled {
		if let task = status.tasks.first {
			var parts: [String] = []
			if let album = task.album {
				parts.append("Album \(album.index)/\(album.count): \(album.title)")
			}
			if let track = task.track {
				parts.append("Track \(track.index)/\(track.count): \(track.title)")
			}
			let report = parts.isEmpty ? task.title : parts.joined(separator: " – ")
			if report != lastReport {
				progress(report)
				lastReport = report
			}
		}
		try? await Task.sleep(for: .milliseconds(200))
	}
}
