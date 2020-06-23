//
//  ViewRefreshing.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 26.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib
import Cocoa

extension ViewState {
	func refreshCurrentView() {
		switch stack.last?.viewType {
		case .search:
			search()

		case .newReleases:
			newReleases()
		case .myMixes:
			myMixes()

		case .favoriteArtists:
			favoriteArtists()
		case .favoriteAlbums:
			favoriteAlbums()
		case .favoritePlaylists:
			favoritePlaylists()
		case .favoriteTracks:
			favoriteTracks()
		case .favoriteVideos:
			favoriteVideos()
		
		case .offlineAlbums:
			offlineAlbums()
		case .offlinePlaylists:
			offlinePlaylists()
		case .offlineTracks:
			offlineTracks()

		case .artist:
			artist()
		case .album:
			album()
		case .playlist:
			playlist()
		case .mix:
			mix()
		
		case nil:
			doNothing()
		}
		
		if let workItem = workItem {
			DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
		}
	}
	
	// Only replaces if actually different
	// Also replaces View in History
	func replaceCurrentView(with view: TidalSwiftView) {
		DispatchQueue.main.async { [self] in
			print("replaceCurrentView(): \(stack.last?.viewType.rawValue ?? "nil")")
			if stack.isEmpty {
				print("replaceCurrentView(): ERROR! Stack is empty, but shouldn't at this point. Aborting.")
				return
			}
			if view == stack.last! {
				print("replaceCurrentView(): Fetched View \(view.viewType.rawValue) is exactly the same, so it's not replaced")
				return
			}
			if stack.last!.id == view.id {
				stack[stack.count - 1] = view
				if !history.isEmpty {
					if history.last!.id == view.id {
						history[history.count - 1] = view
					} else {
						addToHistory(view)
					}
				}
			} else {
				print("replaceCurrentView(): Fetched View \(view.viewType.rawValue) is completely different View, so it's not replaced")
			}
		}
	}
	
	func doNothing() {
		print("ViewState doNothing(): \(stack.last?.viewType.rawValue ?? "nil")")
		workItem = nil
	}
}

extension ViewState {
	func search() {
		guard var view = stack.last else {
			return
		}
		
		view.searchResponse = cache.searchResponses[searchTerm]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = searchWI(searchTerm: searchTerm)
	}
	
	func doSearch(term: String) {
		if stack.last?.viewType != .search {
			return
		}
		if searchTerm == lastSearchTerm || searchTerm.isEmpty {
			return
		}
		lastSearchTerm = searchTerm
		workItem?.cancel()
		
		search()
		DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
	}
	
	func searchWI(searchTerm: String) -> DispatchWorkItem {
		DispatchWorkItem { [self] in
			let t = session.search(for: searchTerm)
			
			var view = TidalSwiftView(viewType: .search)
			if t != nil {
				view.searchResponse = t
				view.loadingState = .successful
				cache.searchResponses[searchTerm] = t
			} else {
				view.searchResponse = cache.searchResponses[searchTerm]
				view.loadingState = .error
			}
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func newReleases() {
		var view = TidalSwiftView(viewType: .newReleases)
		view.albums = cache.newReleases
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = newReleasesWI
	}
	
	var newReleasesWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			let t = session.helpers.newReleasesFromFavoriteArtists(number: 40)
			
			var view = TidalSwiftView(viewType: .newReleases)
			if t != nil {
				view.albums = t
				view.loadingState = .successful
				cache.newReleases = t
			} else {
				view.albums = cache.newReleases
				view.loadingState = .error
			}
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func myMixes() {
		var view = TidalSwiftView(viewType: .myMixes)
		view.mixes = cache.mixes
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = myMixesWI
	}
	
	var myMixesWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			let t = session.getMixes()
			
			var view = TidalSwiftView(viewType: .myMixes)
			if t != nil {
				view.mixes = t
				view.loadingState = .successful
				cache.mixes = t
			} else {
				view.mixes = cache.mixes
				view.loadingState = .error
			}
			
			replaceCurrentView(with: view)
		}
	}
	
	func mix() {
		guard var view = stack.last else {
			return
		}
		guard let mixId = view.mix?.id else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.mixTracks[mixId]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = mixWI
	}
	
	var mixWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			guard var view = stack.last else {
				return
			}
			
			var t: [Track]?
			if let mix = view.mix {
				t = session.getMixPlaylistTracks(mixId: mix.id)
				
				if t != nil {
					view.tracks = t
					view.loadingState = .successful
					cache.mixTracks[mix.id] = t
				} else {
					if let mixId = view.mix?.id {
						view.tracks = cache.mixTracks[mixId]
					}
					view.loadingState = .error
				}
				
				replaceCurrentView(with: view)
			}
		}
	}
}

extension ViewState {
	func favoriteArtists() {
		var view = TidalSwiftView(viewType: .favoriteArtists)
		view.artists = cache.favoriteArtists
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = favoriteArtistsWI
	}
	
	var favoriteArtistsWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			var view = TidalSwiftView(viewType: .favoriteArtists)
			guard let favorites = session.favorites else {
				view.artists = cache.favoriteArtists
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			guard let favA = favorites.artists(order: .dateAdded, orderDirection: .descending) else {
				view.artists = cache.favoriteArtists
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			let t = favA.unwrapped()
			
			view.artists = t
			view.loadingState = .successful
			cache.favoriteArtists = t
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func favoriteAlbums() {
		var view = TidalSwiftView(viewType: .favoriteAlbums)
		view.albums = cache.favoriteAlbums
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = favoriteAlbumsWI
	}
	
	var favoriteAlbumsWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			var view = TidalSwiftView(viewType: .favoriteAlbums)
			guard let favorites = session.favorites else {
				view.albums = cache.favoriteAlbums
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			guard let favA = favorites.albums(order: .dateAdded, orderDirection: .descending) else {
				view.albums = cache.favoriteAlbums
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			let t = favA.unwrapped()
			
			view.albums = t
			view.loadingState = .successful
			cache.favoriteAlbums = t
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func favoritePlaylists() {
		var view = TidalSwiftView(viewType: .favoritePlaylists)
		view.playlists = cache.favoritePlaylists
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = favoritePlaylistsWI
	}
	
	var favoritePlaylistsWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			var view = TidalSwiftView(viewType: .favoritePlaylists)
			guard let favorites = session.favorites else {
				view.playlists = cache.favoritePlaylists
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			guard let favP = favorites.playlists(order: .dateAdded, orderDirection: .descending) else {
				view.playlists = cache.favoritePlaylists
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			let t = favP.unwrapped()
			
			view.playlists = t
			view.loadingState = .successful
			cache.favoritePlaylists = t
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func favoriteTracks() {
		var view = TidalSwiftView(viewType: .favoriteTracks)
		view.tracks = cache.favoriteTracks
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = favoriteTracksWI
	}
	
	var favoriteTracksWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			var view = TidalSwiftView(viewType: .favoriteTracks)
			guard let favorites = session.favorites else {
				view.tracks = cache.favoriteTracks
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			guard let favT = favorites.tracks(order: .dateAdded, orderDirection: .descending) else {
				view.tracks = cache.favoriteTracks
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			let t = favT.unwrapped()
			
			view.tracks = t
			view.loadingState = .successful
			cache.favoriteTracks = t
			
			session.helpers.offline.asyncSyncFavoriteTracks()
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func favoriteVideos() {
		var view = TidalSwiftView(viewType: .favoriteVideos)
		view.videos = cache.favoriteVideos
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = favoriteVideosWI
	}
	
	var favoriteVideosWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			var view = TidalSwiftView(viewType: .favoriteVideos)
			guard let favorites = session.favorites else {
				view.videos = cache.favoriteVideos
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			guard let favV = favorites.videos(order: .dateAdded, orderDirection: .descending) else {
				view.videos = cache.favoriteVideos
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			let t = favV.unwrapped()
			
			view.videos = t
			view.loadingState = .successful
			cache.favoriteVideos = t
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func artist() {
		guard var view = stack.last else {
			return
		}
		guard let artist = stack.last?.artist else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.artistTopTracks[artist.id]
		view.albums = cache.artistAlbums[artist.id]
		view.albumsEpsAndSingles = cache.artistAlbumsEpsAndSingles[artist.id]
		view.albumsAppearances = cache.artistAlbumsAppearances[artist.id]
		view.videos = cache.artistVideos[artist.id]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = artistWI
	}
	
	var artistWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			guard var view = stack.last else {
				return
			}
			
			guard let artist = stack.last?.artist else {
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			if artist.url == nil {
				print("Album incomplete. Loading complete Artist: \(artist.name)")
				if let tArtist = session.getArtist(artistId: artist.id) {
					view.artist = tArtist
				} else {
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
			}
			
			view.tracks = session.getArtistTopTracks(artistId: artist.id, limit: 30, offset: 0)
			view.albums = session.getArtistAlbums(artistId: artist.id)
			view.albumsEpsAndSingles = session.getArtistAlbums(artistId: artist.id, filter: .epsAndSingles)
			view.albumsAppearances = session.getArtistAlbums(artistId: artist.id, filter: .appearances)
			view.videos = session.getArtistVideos(artistId: artist.id)
			
			if view.tracks != nil && view.albums != nil && view.videos != nil {
				view.loadingState = .successful
				cache.artistTopTracks[artist.id] = view.tracks
				cache.artistAlbums[artist.id] = view.albums
				cache.artistVideos[artist.id] = view.videos
			} else {
				view.loadingState = .error
			}
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func album() {
		guard var view = stack.last else {
			return
		}
		guard let album = stack.last?.album else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.albumTracks[album.id] ?? session.helpers.offline.getTracks(for: album)
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = albumWI
	}
	
	var albumWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			guard var view = stack.last else {
				return
			}
			
			guard let album = stack.last?.album else {
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			if album.releaseDate == nil {
				print("Album incomplete. Loading complete album: \(album.title)")
				if let tAlbum = session.getAlbum(albumId: album.id) {
					view.album = tAlbum
				} else {
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
			}
			
			view.tracks = session.getAlbumTracks(albumId: album.id)
			
			if view.tracks != nil {
				view.loadingState = .successful
				cache.albumTracks[album.id] = view.tracks
			} else {
				view.loadingState = .error
				view.tracks = session.helpers.offline.getTracks(for: album)
			}
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func playlist() {
		guard var view = stack.last else {
			return
		}
		guard let playlist = stack.last?.playlist else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.playlistTracks[playlist.id] ?? session.helpers.offline.getTracks(for: playlist)
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = playlistWI
	}
	
	var playlistWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			guard var view = stack.last else {
				return
			}
			
			guard let playlist = stack.last!.playlist else {
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
			
			view.tracks = session.getPlaylistTracks(playlistId: playlist.id)
			
			if view.tracks != nil {
				view.loadingState = .successful
				cache.playlistTracks[playlist.id] = view.tracks
				session.helpers.offline.syncPlaylist(playlist)
			} else {
				view.loadingState = .error
				view.tracks = session.helpers.offline.getTracks(for: playlist)
			}
			
			replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func offlinePlaylists() {
		guard var view = stack.last else {
			return
		}
		
		view.playlists = session.helpers.offline.allOfflinePlaylists()
		view.loadingState = .successful
		replaceCurrentView(with: view)
	}
	
	func offlineAlbums() {
		guard var view = stack.last else {
			return
		}
		
		view.albums = session.helpers.offline.allOfflineAlbums()
		view.loadingState = .successful
		replaceCurrentView(with: view)
	}
	
	func offlineTracks() {
		guard var view = stack.last else {
			return
		}
		
		view.tracks = session.helpers.offline.allOfflineTracks()
		view.loadingState = .successful
		replaceCurrentView(with: view)
	}
}
