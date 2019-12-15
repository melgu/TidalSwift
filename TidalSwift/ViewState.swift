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
	var searchTerm: String = ""
	var artist: Artist? = nil
	var album: Album? = nil
	var playlist: Playlist? = nil
	var mix: MixesItem? = nil
	
	var loadingState: LoadingState = .loading
	
	// Offline
	var searchResponse: SearchResponse? = nil
	var mixes: [MixesItem]? = nil
	var artists: [Artist]? = nil
	var albums: [Album]? = nil
	var playlists: [Playlist]? = nil
	var tracks: [Track]? = nil
	var videos: [Video]? = nil
	
	static func == (lhs: TidalSwiftView, rhs: TidalSwiftView) -> Bool {
		return lhs.viewType == rhs.viewType && lhs.artist == rhs.artist
			&& lhs.album == rhs.album && lhs.playlist == rhs.playlist
			&& lhs.mix == rhs.mix && lhs.loadingState == rhs.loadingState
			&& lhs.searchResponse == rhs.searchResponse && lhs.mixes == rhs.mixes
			&& lhs.artists == rhs.artists && lhs.albums == rhs.albums
			&& lhs.playlists == rhs.playlists && lhs.tracks == rhs.tracks
			&& lhs.videos == rhs.videos
	}
}

final class ViewState: ObservableObject {
	let session: Session
	var cache: ViewCache
	
	@Published var searchTerm: String = ""
	@Published var stack: [TidalSwiftView] = []
	@Published var history: [TidalSwiftView] = []
	var maxHistoryItems: Int = 100
	
	var workItem: DispatchWorkItem? = nil
	var lastSearchTerm: String = ""
	
	var searchTermCancellable: AnyCancellable?
	
	init(session: Session, cache: ViewCache) {
		self.session = session
		self.cache = cache
		
		searchTermCancellable = $searchTerm.receive(on: DispatchQueue.main).sink(receiveValue: doSearch(term:))
	}
	
	func push(view: TidalSwiftView) {
		workItem?.cancel() // Cancel background operation, so no newer View is replaced, if switching views faster than background operation finishes.
		var tempView = view
		tempView.searchTerm = searchTerm
		stack.append(tempView)
		addToHistory(view)
		refreshCurrentView()
//		print("View Push: Search: \(searchTerm)")
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
	}
	
	func clearStack() {
		searchTerm = ""
		stack.removeAll()
	}
	
	func addToHistory(_ view: TidalSwiftView) {
		// Ensure View only exists once in History
		history.removeAll(where: { $0 == view })
		
		history.append(view)
		
		// Enforce Maximum
		if history.count > maxHistoryItems {
			history.removeFirst(history.count - maxHistoryItems)
		}
		print("History count: \(history.count). Max items: \(maxHistoryItems)")
	}
	
	func clearHistory() {
		print("Clear History")
		history.removeAll()
		cache = ViewCache()
	}
}
