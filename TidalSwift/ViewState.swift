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
		if lhs.loadingState != rhs.loadingState {
			return false
		}
		if lhs.viewType == rhs.viewType {
			if lhs.viewType == .search {
				return lhs.searchTerm == rhs.searchTerm
					&& lhs.searchResponse == rhs.searchResponse
			}
			
			else if lhs.viewType == .newReleases {
				return lhs.albums == rhs.albums
			} else if lhs.viewType == .myMixes {
				return lhs.mixes == rhs.mixes
			}
			
			else if lhs.viewType == .favoriteArtists {
				return lhs.artists == rhs.artists
			} else if lhs.viewType == .favoriteAlbums {
				return lhs.albums == rhs.albums
			} else if lhs.viewType == .favoritePlaylists {
				return lhs.playlists == rhs.playlists
			} else if lhs.viewType == .favoriteTracks {
				return lhs.tracks == rhs.tracks
			} else if lhs.viewType == .favoriteVideos {
				return lhs.videos == rhs.videos
			}
			
			else if lhs.viewType == .artist {
				if lhs.artist == rhs.artist {
					return lhs.tracks == rhs.tracks
						&& lhs.albums == rhs.albums
						&& lhs.videos == rhs.videos
				}
			} else if lhs.viewType == .album {
				if lhs.album == rhs.album {
					return lhs.tracks == rhs.tracks
				}
			} else if lhs.viewType == .playlist {
				if lhs.playlist == rhs.playlist {
					return lhs.tracks == rhs.tracks
				}
			} else if lhs.viewType == .mix {
				if lhs.mix == rhs.mix {
					return lhs.tracks == rhs.tracks
				}
			}
			
			else {
				print("View Type \(lhs.viewType) not covered")
				return true
			}
		}
		return false
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
	
	init(session: Session, cache: ViewCache) {
		self.session = session
		self.cache = cache
		
		_ = $searchTerm.receive(on: DispatchQueue.main).sink(receiveValue: doSearch(term:))
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
	
	func clearQueue() {
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
		cache = ViewCache()
	}
}
