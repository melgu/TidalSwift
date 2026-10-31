//
//  Playlists.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct PlaylistDetails: Codable {
	struct Item: Codable {
		/// Starts at 1, as used by remove and move
		let position: Int
		let track: TrackSummary
	}
	
	let playlist: PlaylistSummary
	let items: [Item]
}

/// The account's own playlists and the ones it added to its favorites
@MainActor
func playlists(session: Session, ownOnly: Bool) async throws -> [PlaylistSummary] {
	guard let favorites = await session.favorites?.playlists(order: .name, orderDirection: .ascending) else {
		throw CLIError("Couldn't load playlists")
	}
	let summaries = favorites.map { PlaylistSummary($0.playlist, session: session) }
	return ownOnly ? summaries.filter(\.isOwn) : summaries
}

@MainActor
func playlistDetails(session: Session, reference: String) async throws -> PlaylistDetails {
	let playlist = try await loadPlaylist(reference: reference, session: session)
	guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
		throw CLIError("Couldn't load the tracks of \(playlist.title)")
	}
	return PlaylistDetails(
		playlist: PlaylistSummary(playlist, session: session),
		items: tracks.enumerated().map { PlaylistDetails.Item(position: $0.offset + 1, track: TrackSummary($0.element)) }
	)
}

@MainActor
func createPlaylist(session: Session, title: String, description: String) async throws -> PlaylistSummary {
	guard let playlist = await session.playlistEditing.create(title: title, description: description) else {
		throw CLIError("Couldn't create the playlist")
	}
	return PlaylistSummary(playlist, session: session)
}

/// Keeps the description unless a new one is given
@MainActor
func editPlaylist(session: Session, reference: String, title: String?, description: String?) async throws -> PlaylistSummary {
	let playlist = try await ownPlaylist(reference: reference, session: session)
	guard await session.playlistEditing.edit(
		playlistId: playlist.uuid,
		title: title ?? playlist.title,
		description: description ?? playlist.description ?? ""
	) else {
		throw CLIError("Couldn't change \(playlist.title)")
	}
	return PlaylistSummary(try await loadPlaylist(reference: playlist.uuid, session: session), session: session)
}

@MainActor
func deletePlaylist(session: Session, reference: String) async throws -> PlaylistSummary {
	let playlist = try await ownPlaylist(reference: reference, session: session)
	guard await session.playlistEditing.delete(playlistId: playlist.uuid) else {
		throw CLIError("Couldn't delete \(playlist.title)")
	}
	return PlaylistSummary(playlist, session: session)
}

struct PlaylistAddition: Codable {
	let added: [TrackSummary]
	/// In the playlist already, or given twice
	let skipped: [TrackSummary]
}

/// Adds tracks, or every track of albums and playlists
@MainActor
func addToPlaylist(session: Session, reference: String, items: [String], kind: ItemKind?, allowDuplicates: Bool) async throws -> PlaylistAddition {
	let playlist = try await ownPlaylist(reference: reference, session: session)
	var tracks: [Track] = []
	for item in items {
		tracks += try await resolveTracks(of: TidalLink(reference: item, kind: kind), session: session)
	}
	
	// Tidal skips duplicates without saying so, so they're filtered here to report them
	var skipped: [Track] = []
	if !allowDuplicates {
		guard let existing = await session.playlistTracks(playlistId: playlist.uuid) else {
			throw CLIError("Couldn't load the tracks of \(playlist.title)")
		}
		var seen = Set(existing.map(\.id))
		let all = tracks
		tracks = []
		for track in all {
			if seen.insert(track.id).inserted {
				tracks.append(track)
			} else {
				skipped.append(track)
			}
		}
	}
	
	if !tracks.isEmpty {
		guard await session.playlistEditing.addTracks(tracks.map(\.id), to: playlist.uuid, duplicate: allowDuplicates) else {
			throw CLIError("Couldn't add the tracks to \(playlist.title)")
		}
	}
	return PlaylistAddition(added: tracks.map(TrackSummary.init), skipped: skipped.map(TrackSummary.init))
}

/// Removes the items at the given positions, which start at 1. Returns the removed tracks.
@MainActor
func removeFromPlaylist(session: Session, reference: String, positions: [Int]) async throws -> [TrackSummary] {
	let playlist = try await ownPlaylist(reference: reference, session: session)
	guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
		throw CLIError("Couldn't load the tracks of \(playlist.title)")
	}
	let positions = Set(positions)
	if let invalid = positions.first(where: { !tracks.indices.contains($0 - 1) }) {
		throw CLIError("\(playlist.title) has no position \(invalid). It has \(tracks.count) items.")
	}
	
	// From the back, so earlier positions don't shift
	var removed: [TrackSummary] = []
	for position in positions.sorted(by: >) {
		guard await session.playlistEditing.removeItem(atIndex: position - 1, from: playlist.uuid) else {
			throw CLIError("Couldn't remove position \(position) from \(playlist.title)")
		}
		removed.insert(TrackSummary(tracks[position - 1]), at: 0)
	}
	return removed
}

/// Positions start at 1. Returns the moved track.
@MainActor
func moveInPlaylist(session: Session, reference: String, from: Int, to: Int) async throws -> TrackSummary {
	let playlist = try await ownPlaylist(reference: reference, session: session)
	guard let tracks = await session.playlistTracks(playlistId: playlist.uuid) else {
		throw CLIError("Couldn't load the tracks of \(playlist.title)")
	}
	for position in [from, to] where !tracks.indices.contains(position - 1) {
		throw CLIError("\(playlist.title) has no position \(position). It has \(tracks.count) items.")
	}
	guard await session.playlistEditing.moveItem(fromIndex: from - 1, toIndex: to - 1, in: playlist.uuid) else {
		throw CLIError("Couldn't move position \(from) in \(playlist.title)")
	}
	return TrackSummary(tracks[from - 1])
}

@MainActor
private func ownPlaylist(reference: String, session: Session) async throws -> Playlist {
	let playlist = try await loadPlaylist(reference: reference, session: session)
	guard playlist.creator.id == session.userId else {
		throw CLIError("\(playlist.title) belongs to someone else, so it can't be changed")
	}
	return playlist
}

/// A track itself, or the tracks of an album or playlist
@MainActor
func resolveTracks(of link: TidalLink, session: Session) async throws -> [Track] {
	switch link {
	case .track(let id):
		guard let track = await session.track(trackId: id) else {
			throw CLIError("Couldn't load track \(id)")
		}
		return [track]
	case .album(let id):
		guard let tracks = await session.albumTracks(albumId: id) else {
			throw CLIError("Couldn't load the tracks of album \(id)")
		}
		return tracks
	case .playlist(let uuid):
		guard let tracks = await session.playlistTracks(playlistId: uuid) else {
			throw CLIError("Couldn't load the tracks of playlist \(uuid)")
		}
		return tracks
	case .artist, .video:
		throw CLIError("Only tracks, albums and playlists can be added to a playlist")
	}
}
