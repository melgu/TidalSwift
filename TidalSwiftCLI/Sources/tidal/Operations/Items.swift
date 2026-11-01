//
//  Items.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

// Compact versions of the library's models, with what's useful to read and to pass on to
// other commands. The full models carry dozens of fields that would only bloat the output.

struct TrackSummary: Codable {
	let id: Int
	/// Includes the version, e.g. "Song (Live)"
	let title: String
	let artists: String
	let album: String
	let albumId: Int
	/// In seconds
	let duration: Int
	let explicit: Bool
	let url: URL
}

struct AlbumSummary: Codable {
	let id: Int
	let title: String
	let artists: String?
	let releaseDate: Date?
	let numberOfTracks: Int?
	let explicit: Bool?
	/// Tidal often lists the Dolby Atmos and Hi-Res versions as separate albums
	let dolbyAtmos: Bool
	/// Only for streaming, downloads are 16 bit either way
	let hiRes: Bool
	let url: URL?
}

struct ArtistSummary: Codable {
	let id: Int
	let name: String
	let url: URL?
}

struct PlaylistSummary: Codable {
	let uuid: String
	let title: String
	let creator: String?
	let numberOfTracks: Int
	let description: String?
	/// Only the account's own playlists can be edited
	let isOwn: Bool
	let url: URL
}

struct VideoSummary: Codable {
	let id: Int
	let title: String
	let artists: String
	/// In seconds
	let duration: Int
	let url: URL
}

extension TrackSummary {
	@MainActor
	init(_ track: Track) {
		self.init(
			id: track.id,
			title: track.version.map { "\(track.title) (\($0))" } ?? track.title,
			artists: track.artists.formArtistString(),
			album: track.album.title,
			albumId: track.album.id,
			duration: track.duration,
			explicit: track.explicit,
			url: track.url
		)
	}
}

extension AlbumSummary {
	@MainActor
	init(_ album: Album) {
		self.init(
			id: album.id,
			// Unlike track titles, album titles include the version already
			title: album.title,
			artists: (album.artists ?? album.artist.map { [$0] })?.formArtistString(),
			releaseDate: album.releaseDate,
			numberOfTracks: album.numberOfTracks,
			explicit: album.explicit,
			dolbyAtmos: album.audioModes?.contains(.dolbyAtmos) ?? false,
			hiRes: album.hasHiRes,
			url: album.url
		)
	}
}

extension ArtistSummary {
	@MainActor
	init(_ artist: Artist) {
		self.init(id: artist.id, name: artist.name, url: artist.url)
	}
}

extension PlaylistSummary {
	@MainActor
	init(_ playlist: Playlist, session: Session) {
		self.init(
			uuid: playlist.uuid,
			title: playlist.title,
			creator: playlist.creator.name,
			numberOfTracks: playlist.numberOfTracks,
			description: playlist.description.flatMap { $0.isEmpty ? nil : $0 },
			isOwn: playlist.creator.id == session.userId,
			url: playlist.url
		)
	}
}

extension VideoSummary {
	@MainActor
	init(_ video: Video) {
		self.init(
			id: video.id,
			title: video.title,
			artists: video.artists.formArtistString(),
			duration: video.duration,
			url: URL(string: "https://tidal.com/browse/video/\(video.id)")!
		)
	}
}
