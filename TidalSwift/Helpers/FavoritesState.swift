//
//  FavoritesState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 13.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import OSLog
import TidalSwiftLib

private let logger = Logger(category: "FavoritesState")

/// The IDs of the favorites, so views and context menus can tell right away whether something is a favorite.
///
/// Context menus are built once when they open, so a state they load themselves comes too late.
/// Loaded after the login and whenever the app becomes active, and changed along with every favorite edit made in the app.
@Observable
final class FavoritesState {
	@ObservationIgnored private let session: Session
	
	private(set) var trackIds: Set<Int> = []
	private(set) var albumIds: Set<Int> = []
	private(set) var artistIds: Set<Int> = []
	private(set) var videoIds: Set<Int> = []
	private(set) var playlistIds: Set<String> = []
	
	@ObservationIgnored private var refreshTask: Task<Void, Never>?
	
	init(session: Session) {
		self.session = session
	}
	
	func contains(track: Track) -> Bool {
		trackIds.contains(track.id)
	}
	
	func contains(album: Album) -> Bool {
		albumIds.contains(album.id)
	}
	
	func contains(artist: Artist) -> Bool {
		artistIds.contains(artist.id)
	}
	
	func contains(video: Video) -> Bool {
		videoIds.contains(video.id)
	}
	
	func contains(playlist: Playlist) -> Bool {
		playlistIds.contains(playlist.uuid)
	}
	
	// MARK: - Loading
	
	/// Loads all favorites. A list that fails to load keeps what it had.
	func refresh() {
		refreshTask?.cancel()
		refreshTask = Task {
			guard let favorites = session.favorites else { return }
			async let tracks = favorites.tracks()
			async let albums = favorites.albums()
			async let artists = favorites.artists()
			async let videos = favorites.videos()
			async let playlists = favorites.playlists()
			let loaded = await (tracks, albums, artists, videos, playlists)
			guard !Task.isCancelled else { return }
			
			if let tracks = loaded.0 { trackIds = Set(tracks.map(\.item.id)) }
			if let albums = loaded.1 { albumIds = Set(albums.map(\.item.id)) }
			if let artists = loaded.2 { artistIds = Set(artists.map(\.item.id)) }
			if let videos = loaded.3 { videoIds = Set(videos.map(\.item.id)) }
			if let playlists = loaded.4 { playlistIds = Set(playlists.map(\.playlist.uuid)) }
			logger.debug("Loaded \(self.trackIds.count) tracks, \(self.albumIds.count) albums, \(self.artistIds.count) artists, \(self.videoIds.count) videos and \(self.playlistIds.count) playlists")
		}
	}
	
	/// After logging out
	func clear() {
		refreshTask?.cancel()
		trackIds = []
		albumIds = []
		artistIds = []
		videoIds = []
		playlistIds = []
	}
	
	// MARK: - Editing
	// Each returns whether Tidal accepted the change
	
	@discardableResult func addTrack(trackId: Int) async -> Bool {
		await change { await $0.addTrack(trackId: trackId) } then: { _ = trackIds.insert(trackId) }
	}
	
	@discardableResult func removeTrack(trackId: Int) async -> Bool {
		await change { await $0.removeTrack(trackId: trackId) } then: { _ = trackIds.remove(trackId) }
	}
	
	@discardableResult func addAlbum(albumId: Int) async -> Bool {
		await change { await $0.addAlbum(albumId: albumId) } then: { _ = albumIds.insert(albumId) }
	}
	
	@discardableResult func removeAlbum(albumId: Int) async -> Bool {
		await change { await $0.removeAlbum(albumId: albumId) } then: { _ = albumIds.remove(albumId) }
	}
	
	@discardableResult func addArtist(artistId: Int) async -> Bool {
		await change { await $0.addArtist(artistId: artistId) } then: { _ = artistIds.insert(artistId) }
	}
	
	@discardableResult func removeArtist(artistId: Int) async -> Bool {
		await change { await $0.removeArtist(artistId: artistId) } then: { _ = artistIds.remove(artistId) }
	}
	
	@discardableResult func addVideo(videoId: Int) async -> Bool {
		await change { await $0.addVideo(videoId: videoId) } then: { _ = videoIds.insert(videoId) }
	}
	
	@discardableResult func removeVideo(videoId: Int) async -> Bool {
		await change { await $0.removeVideo(videoId: videoId) } then: { _ = videoIds.remove(videoId) }
	}
	
	@discardableResult func addPlaylist(playlistId: String) async -> Bool {
		await change { await $0.addPlaylist(playlistId: playlistId) } then: { _ = playlistIds.insert(playlistId) }
	}
	
	@discardableResult func removePlaylist(playlistId: String) async -> Bool {
		await change { await $0.removePlaylist(playlistId: playlistId) } then: { _ = playlistIds.remove(playlistId) }
	}
	
	private func change(_ request: (Favorites) async -> Bool, then update: () -> Void) async -> Bool {
		guard let favorites = session.favorites, await request(favorites) else { return false }
		update()
		return true
	}
}
