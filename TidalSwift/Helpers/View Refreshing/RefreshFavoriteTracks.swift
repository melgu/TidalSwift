//
//  RefreshFavoriteTracks.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
			Task {
				var view = TidalSwiftView(viewType: .favoriteTracks)
				guard let favorites = session.favorites else {
					view.tracks = cache.favoriteTracks
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				guard let favT = await favorites.tracks(order: .dateAdded, orderDirection: .descending) else {
					view.tracks = cache.favoriteTracks
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				
				let t = favT.unwrapped()
				
				view.tracks = t
				view.loadingState = .successful
				cache.favoriteTracks = t
				
				await session.helpers.offline.asyncSyncFavoriteTracks()
				replaceCurrentView(with: view)
			}
		}
	}
}
