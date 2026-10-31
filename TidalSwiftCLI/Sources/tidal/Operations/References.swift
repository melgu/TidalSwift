//
//  References.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

enum ItemKind: String, CaseIterable, Codable {
	case track
	case album
	case artist
	case playlist
	case video
}

extension TidalLink {
	/// Accepts a Tidal link, a playlist UUID, or an ID. A bare ID needs its kind, as tracks, albums,
	/// artists and videos share the same number space. Links and UUIDs ignore the kind, so they can be mixed with IDs.
	init(reference: String, kind: ItemKind?) throws {
		let reference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
		if let link = TidalLink(string: reference) {
			self = link
			return
		}
		
		if UUID(uuidString: reference) != nil {
			self = .playlist(uuid: reference.lowercased())
			return
		}
		
		guard let id = Int(reference) else {
			throw CLIError("\(reference) is neither a Tidal link nor an ID")
		}
		switch kind {
		case nil:
			throw CLIError("Pass --type to say what \(id) is, or use a link instead")
		case .track:
			self = .track(id: id)
		case .album:
			self = .album(id: id)
		case .artist:
			self = .artist(id: id)
		case .video:
			self = .video(id: id)
		case .playlist:
			throw CLIError("Playlists are identified by a UUID, not a number")
		}
	}
	
	var kind: ItemKind {
		switch self {
		case .track: .track
		case .album: .album
		case .artist: .artist
		case .playlist: .playlist
		case .video: .video
		}
	}
}

/// A playlist by link or UUID
@MainActor
func loadPlaylist(reference: String, session: Session) async throws -> Playlist {
	guard case .playlist(let uuid) = try TidalLink(reference: reference, kind: .playlist) else {
		throw CLIError("\(reference) isn't a playlist")
	}
	guard let playlist = await session.playlist(playlistId: uuid) else {
		throw CLIError("Couldn't load playlist \(uuid)")
	}
	return playlist
}
