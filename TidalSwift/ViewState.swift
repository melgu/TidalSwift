//
//  ViewState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
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
	
//	case none = ""
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
	
	// Offline
	var playlists: [Playlist]? = nil
	var artists: [Artist]? = nil
	var albums: [Album]? = nil
	var tracks: [Track]? = nil
	var videos: [Video]? = nil
	
	static func == (lhs: TidalSwiftView, rhs: TidalSwiftView) -> Bool {
		if lhs.viewType == rhs.viewType {
			if lhs.viewType == .artist {
				return lhs.artist == rhs.artist
			} else if lhs.viewType == .album {
				return lhs.album == rhs.album
			} else if lhs.viewType == .playlist {
				return lhs.playlist == rhs.playlist
			} else if lhs.viewType == .mix {
				return lhs.mix == rhs.mix
			} else {
				return true
			}
		} else {
			return false
		}
	}
}

final class ViewState: ObservableObject {
	@Published var searchTerm: String = ""
	@Published var stack: [TidalSwiftView] = []
	@Published var history: [TidalSwiftView] = []
	var maxHistoryItems: Int = 100
	
	func push(view: TidalSwiftView) {
		var tempView = view
		tempView.searchTerm = searchTerm
		stack.append(tempView)
		addToHistory(view)
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
	
	func clear() {
		stack.removeAll()
	}
	
	func addToHistory(_ view: TidalSwiftView) {
		// Ensure View only exists once in History
		history.removeAll(where: { $0 == view })
		
		history.append(view)
		
		// Enforce Maximum
		if history.count >= maxHistoryItems {
			history.removeFirst(history.count - maxHistoryItems)
		}
	}
	
	func clearHistory() {
		history.removeAll()
	}
}
