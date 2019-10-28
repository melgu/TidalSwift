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

struct TidalSwiftView: Codable {
	var viewType: ViewType
	var searchTerm: String = ""
	var artist: Artist? = nil
	var album: Album? = nil
	var playlist: Playlist? = nil
	var mix: MixesItem? = nil
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
	
	func push(view: TidalSwiftView) {
		var tempView = view
		tempView.searchTerm = searchTerm
		
		stack.append(tempView)
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
}
