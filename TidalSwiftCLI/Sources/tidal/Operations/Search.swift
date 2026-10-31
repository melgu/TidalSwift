//
//  Search.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

/// Empty arrays for the kinds that weren't asked for
struct SearchResults: Codable {
	var tracks: [TrackSummary] = []
	var albums: [AlbumSummary] = []
	var artists: [ArtistSummary] = []
	var playlists: [PlaylistSummary] = []
	var videos: [VideoSummary] = []
}

@MainActor
func search(session: Session, term: String, kinds: Set<ItemKind>, limit: Int) async throws -> SearchResults {
	guard let response = await session.search(for: term, limit: limit) else {
		throw CLIError("Search failed")
	}
	
	var results = SearchResults()
	if kinds.contains(.track) {
		results.tracks = response.tracks.map(TrackSummary.init)
	}
	if kinds.contains(.album) {
		results.albums = response.albums.map(AlbumSummary.init)
	}
	if kinds.contains(.artist) {
		results.artists = response.artists.map(ArtistSummary.init)
	}
	if kinds.contains(.playlist) {
		results.playlists = response.playlists.map { PlaylistSummary($0, session: session) }
	}
	if kinds.contains(.video) {
		results.videos = response.videos.map(VideoSummary.init)
	}
	return results
}
