//
//  Metadata.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 30.06.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

/// Format-independent tags, written by `FLACTagWriter` and `MP4TagWriter`
nonisolated struct AudioTags {
	var title: String
	var artist: String?
	var album: String
	var albumArtist: String?
	var trackNumber: Int
	var trackTotal: Int?
	var discNumber: Int
	var discTotal: Int?
	/// Formatted as `yyyy-MM-dd`
	var releaseDate: String?
	var copyright: String?
	var isrc: String?
	var isCompilation: Bool
	var isExplicit: Bool
	var cover: Data?
}

class Metadata {
	private unowned let session: Session
	
	init(session: Session) {
		self.session = session
	}
	
	/// Only works for FLAC & M4A/MP4
	func setMetadata(for track: Track, at path: URL) async {
		let tags = await tags(for: track)
		do {
			switch path.pathExtension.lowercased() {
			case "flac":
				try await FLACTagWriter.write(tags, to: path)
			case "m4a", "mp4":
				try await MP4TagWriter.write(tags, to: path)
			default:
				print("Metadata: Unsupported file type \(path.pathExtension)")
			}
		} catch {
			displayError(title: "Error writing Metadata", content: "Path: \(path). Error: \(error)")
		}
	}
	
	private func tags(for track: Track) async -> AudioTags {
		var title = track.title
		if let version = track.version {
			title += " (\(version))"
		}
		
		var tags = AudioTags(
			title: title,
			artist: track.artists.isEmpty ? nil : track.artists.formArtistString(),
			album: track.album.title,
			trackNumber: track.trackNumber,
			discNumber: track.volumeNumber,
			releaseDate: track.album.releaseDate?.formatted(.iso8601.year().month().day()),
			copyright: track.copyright,
			isrc: track.isrc,
			isCompilation: track.album.isCompilation,
			isExplicit: track.explicit
		)
		
		// The album embedded in a track lacks most details
		if let album = await session.album(albumId: track.album.id) {
			tags.trackTotal = album.numberOfTracks
			tags.discTotal = album.numberOfVolumes
			if let artists = album.artists, !artists.isEmpty {
				tags.albumArtist = artists.formArtistString()
			}
			if tags.releaseDate == nil {
				tags.releaseDate = album.releaseDate?.formatted(.iso8601.year().month().day())
			}
		}
		
		if let coverUrl = track.getCoverUrl(session: session, resolution: 1280) {
			tags.cover = await downloadCover(from: coverUrl)
		}
		
		return tags
	}
	
	private func downloadCover(from url: URL) async -> Data? {
		do {
			let (data, response) = try await URLSession.shared.data(from: url)
			if let statusCode = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(statusCode) {
				print("Metadata: Cover download failed with status \(statusCode)")
				return nil
			}
			return data
		} catch {
			print("Metadata: Cover download failed. Error: \(error)")
			return nil
		}
	}
}
