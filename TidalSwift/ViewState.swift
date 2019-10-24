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
	
	case favoriteArtists = "Artists"
	case favoriteAlbums = "Albums"
	case favoritePlaylists = "Playlists"
	case favoriteTracks = "Tracks"
	case favoriteVideos = "Videos"
	
	case artist = "SingleArtist"
	case album = "SingleAlbum"
	case playlist = "SinglePlaylist"
	
	case none = ""
}

struct TidalSwiftView {
	var viewType: ViewType
	var artist: Artist? = nil
	var album: Album? = nil
	var playlist: Playlist? = nil
}

final class ViewState: ObservableObject {
	@Published var viewType: String?
	@Published var artist: Artist?
	@Published var album: Album?
	@Published var playlist: Playlist?
	
	var stack: [TidalSwiftView] = []
	
	func push(view: TidalSwiftView) {
		stack.append(view)
		viewType = view.viewType.rawValue
		artist = view.artist
		album = view.album
		playlist = view.playlist
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
	
	func pop() {
		stack.removeLast()
		if stack.count > 0 {
			viewType = stack.last!.viewType.rawValue
			artist = stack.last!.artist
			album = stack.last!.album
			playlist = stack.last!.playlist
		} else {
			viewType = ""
			artist = nil
			album = nil
			playlist = nil
		}
	}
	
	func clear() {
		stack.removeAll()
	}
}
