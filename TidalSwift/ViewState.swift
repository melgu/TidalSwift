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
	
	case favoriteArtists = "Artists"
	case favoriteAlbums = "Albums"
	case favoritePlaylists = "Playlists"
	case favoriteTracks = "Tracks"
	case favoriteVideos = "Videos"
	
	case artist = "SingleArtist"
	case album = "SingleAlbum"
	case playlist = "SinglePlaylist"
	case mix = "SingleMix"
	
	case none = ""
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
	@Published var viewType: String?
	var searchTerm: String = ""
	@Published var fixedSearchTerm: String = ""
	@Published var artist: Artist?
	@Published var album: Album?
	@Published var playlist: Playlist?
	@Published var mix: MixesItem?
	
	var stack: [TidalSwiftView] = []
	@Published var history: [TidalSwiftView] = []
	var maxHistoryItems: Int = 100
	
	func push(view: TidalSwiftView) {
		var tempView = view
		tempView.searchTerm = searchTerm
		
		stack.append(tempView)
		addToHistory(view)
		viewType = tempView.viewType.rawValue
		artist = tempView.artist
		album = tempView.album
		playlist = tempView.playlist
		mix = tempView.mix
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
		if stack.count > 0 {
			viewType = stack.last!.viewType.rawValue
			artist = stack.last!.artist
			album = stack.last!.album
			playlist = stack.last!.playlist
			mix = stack.last!.mix
		} else {
			viewType = ""
			artist = nil
			album = nil
			playlist = nil
			mix = nil
		}
	}
	
	func clear() {
		stack.removeAll()
		viewType = ""
		searchTerm = ""
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
