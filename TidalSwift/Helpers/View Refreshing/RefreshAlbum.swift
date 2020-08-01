//
//  RefreshAlbum.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
