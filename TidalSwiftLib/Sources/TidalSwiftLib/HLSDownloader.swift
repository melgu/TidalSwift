//
//  HLSDownloader.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import AVFoundation

/// Downloads the best variant of an HLS stream into an MP4 file, without re-encoding it.
///
/// Tidal's videos are transport stream segments with video and audio muxed together.
/// Joined one after the other, they form a single transport stream, which AVFoundation exports as MP4.
nonisolated public enum HLSDownloader {
	enum DownloadError: Error {
		case invalidServerResponse(statusCode: Int)
		case exportUnavailable
		case exportFailed(Error?)
	}
	
	/// How many segments load at the same time
	private static let parallelSegments = 4
	private static let attempts = 4
	
	/// - Parameter progress: The fraction of segments downloaded so far
	@concurrent
	public static func download(_ manifestURL: URL, to outputURL: URL, tags: VideoTags?, progress: @escaping @MainActor @Sendable (Double) -> Void) async throws {
		let fileManager = FileManager.default
		try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
		let temporaryDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: outputURL, create: true)
		defer { try? fileManager.removeItem(at: temporaryDirectory) }
		
		let (masterData, masterURL) = try await fetch(manifestURL)
		let master = try HLSPlaylist.Master(String(decoding: masterData, as: UTF8.self), baseURL: masterURL)
		let (mediaData, mediaURL) = try await fetch(master.best.url)
		let segments = try HLSPlaylist.Media(String(decoding: mediaData, as: UTF8.self), baseURL: mediaURL).allSegments
		
		let streamURL = temporaryDirectory.appendingPathComponent("stream.ts")
		fileManager.createFile(atPath: streamURL.path, contents: nil)
		let handle = try FileHandle(forWritingTo: streamURL)
		defer { try? handle.close() }
		
		try await withThrowingTaskGroup(of: (Int, Data).self) { group in
			var nextToFetch = 0
			var nextToWrite = 0
			var fetched: [Int: Data] = [:]
			
			func fetchMore() {
				while nextToFetch < segments.count, nextToFetch < nextToWrite + parallelSegments {
					let index = nextToFetch
					let url = segments[index]
					group.addTask {
						(index, try await fetch(url).data)
					}
					nextToFetch += 1
				}
			}
			
			fetchMore()
			while let (index, data) = try await group.next() {
				fetched[index] = data
				// Segments arrive in any order, but have to be written in the playlist's
				while let data = fetched.removeValue(forKey: nextToWrite) {
					try handle.write(contentsOf: data)
					nextToWrite += 1
					await progress(Double(nextToWrite) / Double(segments.count))
				}
				fetchMore()
			}
		}
		try handle.close()
		
		let exportURL = temporaryDirectory.appendingPathComponent("video.mp4")
		guard let exportSession = AVAssetExportSession(asset: AVURLAsset(url: streamURL), presetName: AVAssetExportPresetPassthrough) else {
			throw DownloadError.exportUnavailable
		}
		if let tags {
			exportSession.metadata = MP4TagWriter.metadataItems(for: tags)
		}
		// Puts the index first, so players can start right away
		exportSession.shouldOptimizeForNetworkUse = true
		if #available(macOS 15, iOS 18, *) {
			try await exportSession.export(to: exportURL, as: .mp4)
		} else {
			exportSession.outputURL = exportURL
			exportSession.outputFileType = .mp4
			await exportSession.export()
			guard exportSession.status == .completed else {
				throw DownloadError.exportFailed(exportSession.error)
			}
		}
		
		if fileManager.fileExists(atPath: outputURL.path) {
			try fileManager.removeItem(at: outputURL)
		}
		try fileManager.moveItem(at: exportURL, to: outputURL)
	}
	
	/// Retries network failures, but not responses that won't change
	private static func fetch(_ url: URL) async throws -> (data: Data, url: URL) {
		var attempt = 1
		while true {
			do {
				let (data, response) = try await URLSession.shared.data(from: url)
				guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
				guard response.statusCode == 200 else {
					throw DownloadError.invalidServerResponse(statusCode: response.statusCode)
				}
				// Relative addresses in a playlist refer to where any redirect led
				return (data, response.url ?? url)
			} catch {
				guard attempt < attempts, isTransient(error) else { throw error }
				try await Task.sleep(for: .seconds(attempt * 2))
				attempt += 1
			}
		}
	}
	
	private static func isTransient(_ error: Error) -> Bool {
		switch error {
		case let error as URLError:
			error.code != .cancelled
		case DownloadError.invalidServerResponse(let statusCode):
			statusCode >= 500
		default:
			false
		}
	}
}
