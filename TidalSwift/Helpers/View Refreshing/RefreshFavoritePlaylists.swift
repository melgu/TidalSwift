//
//  RefreshFavoritePlaylists.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
			Task {
				var view = TidalSwiftView(viewType: .favoritePlaylists)
				guard let favorites = session.favorites else {
					view.playlists = cache.favoritePlaylists
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				guard let favP = await favorites.playlists(order: .dateAdded, orderDirection: .descending) else {
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
}
