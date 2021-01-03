//
//  ViewState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

enum ViewType: String, Codable {
	case search = "Search"
	
	case newReleases = "New Releases"
	case myMixes = "My Mixes"
	
	case favoriteArtists = "Favorite Artists"
	case favoriteAlbums = "Favorite Albums"
	case favoritePlaylists = "Favorite Playlists"
	case favoriteTracks = "Favorite Tracks"
	case favoriteVideos = "Favorite Videos"
	
	case offlineAlbums = "Offline Albums"
	case offlinePlaylists = "Offline Playlists"
	case offlineTracks = "Offline Tracks"
//	case offlineVideos = "Favorite Videos" // Add when Video downloading works
	
	case artist = "Artist"
	case album = "Album"
	case playlist = "Playlist"
	case mix = "Mix"
}

struct TidalSwiftView: Codable, Equatable, Identifiable {
	var id: String { viewType.rawValue +
		String(describing: artist?.id) +
		String(describing: album?.id) +
		String(describing: playlist?.uuid) +
		String(describing: mix?.id)
	}
	
	var viewType: ViewType
	var artist: Artist?
	var album: Album?
	var playlist: Playlist?
	var mix: MixesItem?
	
	var loadingState: LoadingState = .loading
	
	var searchResponse: SearchResponse?
	var mixes: [MixesItem]?
	var artists: [Artist]?
	var albums: [Album]?
	var albumsEpsAndSingles: [Album]?	// Artist EPS & Singles
	var albumsAppearances: [Album]?		// Artist Appearances
	var playlists: [Playlist]?
	var tracks: [Track]?
	var videos: [Video]?
	
	static func == (lhs: TidalSwiftView, rhs: TidalSwiftView) -> Bool {
		lhs.viewType == rhs.viewType && lhs.artist == rhs.artist &&
			lhs.album == rhs.album && lhs.playlist == rhs.playlist &&
			lhs.mix == rhs.mix && lhs.loadingState == rhs.loadingState &&
			lhs.searchResponse == rhs.searchResponse && lhs.mixes == rhs.mixes &&
			lhs.artists == rhs.artists && lhs.albums == rhs.albums &&
			lhs.playlists == rhs.playlists && lhs.tracks == rhs.tracks &&
			lhs.videos == rhs.videos
	}
	
	static func equateBase(_ lhs: TidalSwiftView, _ rhs: TidalSwiftView) -> Bool {
		lhs.viewType == rhs.viewType && lhs.artist == rhs.artist &&
			lhs.album == rhs.album && lhs.playlist == rhs.playlist &&
			lhs.mix == rhs.mix
	}
	
	func isBase() -> Bool {
		viewType == .newReleases || viewType == .myMixes ||
			viewType == .favoriteArtists || viewType == .favoriteAlbums ||
			viewType == .favoritePlaylists || viewType == .favoriteTracks ||
			viewType == .favoriteVideos || viewType == .offlineAlbums ||
			viewType == .offlinePlaylists || viewType == .offlineTracks
	}
}

final class ViewState: ObservableObject {
	let session: Session
	var cache: ViewCache
	
	var searchTerm: String = ""
	@Published var newReleasesIncludeEps: Bool = false
	@Published var stack: [TidalSwiftView] = []
	@Published var history: [TidalSwiftView] = []
	var maxHistoryItems: Int = 100
	
	var workItem: DispatchWorkItem?
	var lastSearchTerm: String = ""
	
	init(session: Session, cache: ViewCache) {
		self.session = session
		self.cache = cache
	}
	
	func push(view: TidalSwiftView) {
		workItem?.cancel() // Cancel background operation, so no newer View is replaced, if switching views before background operation finishes.
		stack.append(view)
		if view.viewType != .search {
			addToHistory(view)
		}
		refreshCurrentView()
	}
	
	func push(artist: Artist) {
		let view = TidalSwiftView(viewType: .artist, artist: artist)
		push(view: view)
	}
	
	func push(album: Album) {
		let view = TidalSwiftView(viewType: .album, album: album)
		push(view: view)
	}
	
	func push(playlist: Playlist) {
		let view = TidalSwiftView(viewType: .playlist, playlist: playlist)
		push(view: view)
	}
	
	func push(mix: MixesItem) {
		let view = TidalSwiftView(viewType: .mix, mix: mix)
		push(view: view)
	}
	
	func pop() {
		stack.removeLast()
		refreshCurrentView()
	}
	
	func clearStack() {
		stack.removeAll()
	}
	
	func addToHistory(_ view: TidalSwiftView) {
		// Ensure View only exists once in History
		history.removeAll(where: { TidalSwiftView.equateBase($0, view) })
		
		history.append(view)
		
		// Enforce Maximum
		if history.count > maxHistoryItems {
			history.removeFirst(history.count - maxHistoryItems)
		}
//		print("History count: \(history.count). Max items: \(maxHistoryItems)")
	}
	
	func clearHistory() {
		print("Clear History")
		history.removeAll()
		cache = ViewCache()
	}
	
	func clearEverything() {
		searchTerm = ""
		clearStack()
		clearHistory()
	}
}
