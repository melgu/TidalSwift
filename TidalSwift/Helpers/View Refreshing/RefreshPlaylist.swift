//
//  RefreshPlaylist.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
			
			guard let playlist = stack.last?.playlist else {
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
