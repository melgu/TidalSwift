//
//  RefreshArtist.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
