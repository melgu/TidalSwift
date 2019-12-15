//
//  OfflineViews.swift
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
		switch self.stack.last?.viewType {
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
		DispatchQueue.main.async {
			print("replaceCurrentView(): \(self.stack.last?.viewType.rawValue ?? "nil")")
			var tempView = view
			tempView.searchTerm = self.searchTerm
			if self.stack.isEmpty {
				print("replaceCurrentView(): ERROR! Stack is empty, but shouldn't at this point. Aborting.")
				return
			}
			if view == self.stack.last! {
				print("replaceCurrentView(): Fetched View \(view.viewType.rawValue) is exactly the same, so it's not replaced")
				return
			}
			if self.stack.last!.id == tempView.id {
				self.stack[self.stack.count-1] = tempView
				if !self.history.isEmpty {
					self.history[self.history.count-1] = tempView
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
		
		workItem = searchWI
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
		DispatchQueue.global(qos: .userInitiated).async(execute: searchWI)
	}
	
	var searchWI: DispatchWorkItem {
		return DispatchWorkItem {
			let t = self.session.search(for: self.searchTerm)
			
			var view = TidalSwiftView(viewType: .search)
			if t != nil {
				view.searchResponse = t
				view.loadingState = .successful
				self.cache.searchResponses[self.searchTerm] = t
			} else {
				view.searchResponse = self.cache.searchResponses[self.searchTerm]
				view.loadingState = .error
			}
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			let t = self.session.helpers.newReleasesFromFavoriteArtists(number: 40)
			
			var view = TidalSwiftView(viewType: .newReleases)
			if t != nil {
				view.albums = t
				view.loadingState = .successful
				self.cache.newReleases = t
			} else {
				view.albums = self.cache.newReleases
				view.loadingState = .error
			}
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			let t = self.session.getMixes()
			
			var view = TidalSwiftView(viewType: .myMixes)
			if t != nil {
				view.mixes = t
				view.loadingState = .successful
				self.cache.mixes = t
			} else {
				view.mixes = self.cache.mixes
				view.loadingState = .error
			}
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			guard var view = self.stack.last else {
				return
			}
			
			var t: [Track]?
			if let mix = view.mix {
				t = self.session.getMixPlaylistTracks(mixId: mix.id)
				
				if t != nil {
					view.tracks = t
					view.loadingState = .successful
					self.cache.mixTracks[mix.id] = t
				} else {
					if let mixId = view.mix?.id {
						view.tracks = self.cache.mixTracks[mixId]
					}
					view.loadingState = .error
				}
				
				self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			var view = TidalSwiftView(viewType: .favoriteArtists)
			guard let favorites = self.session.favorites else {
				view.artists = self.cache.favoriteArtists
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			guard let favA = favorites.artists(order: .dateAdded, orderDirection: .descending) else {
				view.artists = self.cache.favoriteArtists
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			let t = favoriteArtists2Artists(favA)
			
			view.artists = t
			view.loadingState = .successful
			self.cache.favoriteArtists = t
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			var view = TidalSwiftView(viewType: .favoriteAlbums)
			guard let favorites = self.session.favorites else {
				view.albums = self.cache.favoriteAlbums
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			guard let favA = favorites.albums(order: .dateAdded, orderDirection: .descending) else {
				view.albums = self.cache.favoriteAlbums
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			let t = favoriteAlbums2Albums(favA)
			
			view.albums = t
			view.loadingState = .successful
			self.cache.favoriteAlbums = t
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			var view = TidalSwiftView(viewType: .favoritePlaylists)
			guard let favorites = self.session.favorites else {
				view.playlists = self.cache.favoritePlaylists
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			guard let favP = favorites.playlists(order: .dateAdded, orderDirection: .descending) else {
				view.playlists = self.cache.favoritePlaylists
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			let t = favoritePlaylists2Playlists(favP)
			
			view.playlists = t
			view.loadingState = .successful
			self.cache.favoritePlaylists = t
			
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			var view = TidalSwiftView(viewType: .favoriteTracks)
			guard let favorites = self.session.favorites else {
				view.tracks = self.cache.favoriteTracks
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			guard let favT = favorites.tracks(order: .dateAdded, orderDirection: .descending) else {
				view.tracks = self.cache.favoriteTracks
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			let t = favoriteTracks2Tracks(favT)
			
			view.tracks = t
			view.loadingState = .successful
			self.cache.favoriteTracks = t
			
			self.session.helpers.offline.asyncSyncFavoriteTracks()
			self.replaceCurrentView(with: view)
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
		return DispatchWorkItem {
			var view = TidalSwiftView(viewType: .favoriteVideos)
			guard let favorites = self.session.favorites else {
				view.videos = self.cache.favoriteVideos
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			guard let favV = favorites.videos(order: .dateAdded, orderDirection: .descending) else {
				view.videos = self.cache.favoriteVideos
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			let t = favoriteVideos2Videos(favV)
			
			view.videos = t
			view.loadingState = .successful
			self.cache.favoriteVideos = t
			
			self.replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func artist() {
		guard var view = stack.last else {
			return
		}
		guard let artist = self.stack.last!.artist else {
			view.loadingState = .error
			self.replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.artistTopTracks[artist.id]
		view.albums = cache.artistAlbums[artist.id]
		view.videos = cache.artistVideos[artist.id]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = artistWI
	}
	
	var artistWI: DispatchWorkItem {
		return DispatchWorkItem {
			guard var view = self.stack.last else {
				return
			}
			
			guard let artist = self.stack.last!.artist else {
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			if artist.url == nil {
				print("Album incomplete. Loading complete Artist: \(artist.name)")
				if let tArtist = self.session.getArtist(artistId: artist.id) {
					view.artist = tArtist
				} else {
					view.loadingState = .error
					self.replaceCurrentView(with: view)
					return
				}
			}
			
			view.tracks = self.session.getArtistTopTracks(artistId: artist.id, limit: 30, offset: 0)
			view.albums = self.session.getArtistAlbums(artistId: artist.id)
			view.videos = self.session.getArtistVideos(artistId: artist.id)
			
			if view.tracks != nil && view.albums != nil && view.videos != nil {
				view.loadingState = .successful
				self.cache.artistTopTracks[artist.id] = view.tracks
				self.cache.artistAlbums[artist.id] = view.albums
				self.cache.artistVideos[artist.id] = view.videos
			} else {
				view.loadingState = .error
			}
			self.replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func album() {
		guard var view = stack.last else {
			return
		}
		guard let album = self.stack.last!.album else {
			view.loadingState = .error
			self.replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.albumTracks[album.id]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = albumWI
	}
	
	var albumWI: DispatchWorkItem {
		return DispatchWorkItem {
			guard var view = self.stack.last else {
				return
			}
			
			guard let album = self.stack.last!.album else {
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			if album.releaseDate == nil {
				print("Album incomplete. Loading complete album: \(album.title)")
				if let tAlbum = self.session.getAlbum(albumId: album.id) {
					view.album = tAlbum
				} else {
					view.loadingState = .error
					self.replaceCurrentView(with: view)
					return
				}
			}
			
			view.tracks = self.session.getAlbumTracks(albumId: album.id)
			
			if view.tracks != nil {
				view.loadingState = .successful
				self.cache.albumTracks[album.id] = view.tracks
			} else {
				view.loadingState = .error
			}
			self.replaceCurrentView(with: view)
		}
	}
}

extension ViewState {
	func playlist() {
		guard var view = stack.last else {
			return
		}
		guard let playlist = self.stack.last!.playlist else {
			view.loadingState = .error
			self.replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.playlistTracks[playlist.id]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = playlistWI
	}
	
	var playlistWI: DispatchWorkItem {
		return DispatchWorkItem {
			guard var view = self.stack.last else {
				return
			}
			
			guard let playlist = self.stack.last!.playlist else {
				view.loadingState = .error
				self.replaceCurrentView(with: view)
				return
			}
			
			view.tracks = self.session.getPlaylistTracks(playlistId: playlist.id)
			
			if view.tracks != nil {
				view.loadingState = .successful
				self.cache.playlistTracks[playlist.id] = view.tracks
				self.session.helpers.offline.syncPlaylist(playlist)
			} else {
				view.loadingState = .error
			}
			
			self.replaceCurrentView(with: view)
		}
	}
}
