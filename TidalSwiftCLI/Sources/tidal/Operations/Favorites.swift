//
//  Favorites.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

/// Newest first. Playlists include the account's own ones, as Tidal lists them together.
@MainActor
func favorites(session: Session, kind: ItemKind) async throws -> SearchResults {
	guard let favorites = session.favorites else {
		throw CLIError("Not logged in")
	}
	
	var results = SearchResults()
	let loaded: Bool
	switch kind {
	case .track:
		let items = await favorites.tracks()
		results.tracks = items?.map { TrackSummary($0.item) } ?? []
		loaded = items != nil
	case .album:
		let items = await favorites.albums()
		results.albums = items?.map { AlbumSummary($0.item) } ?? []
		loaded = items != nil
	case .artist:
		let items = await favorites.artists()
		results.artists = items?.map { ArtistSummary($0.item) } ?? []
		loaded = items != nil
	case .playlist:
		let items = await favorites.playlists()
		results.playlists = items?.map { PlaylistSummary($0.playlist, session: session) } ?? []
		loaded = items != nil
	case .video:
		let items = await favorites.videos()
		results.videos = items?.map { VideoSummary($0.item) } ?? []
		loaded = items != nil
	}
	guard loaded else {
		throw CLIError("Couldn't load favorite \(kind.rawValue)s")
	}
	return results
}

@MainActor
func changeFavorite(session: Session, link: TidalLink, isFavorite: Bool) async throws {
	guard let favorites = session.favorites else {
		throw CLIError("Not logged in")
	}
	
	let success: Bool
	switch (link, isFavorite) {
	case (.track(let id), true): success = await favorites.addTrack(trackId: id)
	case (.track(let id), false): success = await favorites.removeTrack(trackId: id)
	case (.album(let id), true): success = await favorites.addAlbum(albumId: id)
	case (.album(let id), false): success = await favorites.removeAlbum(albumId: id)
	case (.artist(let id), true): success = await favorites.addArtist(artistId: id)
	case (.artist(let id), false): success = await favorites.removeArtist(artistId: id)
	case (.playlist(let uuid), true): success = await favorites.addPlaylist(playlistId: uuid)
	case (.playlist(let uuid), false): success = await favorites.removePlaylist(playlistId: uuid)
	case (.video(let id), true): success = await favorites.addVideo(videoId: id)
	case (.video(let id), false): success = await favorites.removeVideo(videoId: id)
	}
	guard success else {
		throw CLIError(isFavorite ? "Couldn't add to favorites" : "Couldn't remove from favorites")
	}
}
