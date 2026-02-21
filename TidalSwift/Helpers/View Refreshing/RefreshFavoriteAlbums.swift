//
//  RefreshFavoriteAlbums.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
			Task {
				var view = TidalSwiftView(viewType: .favoriteAlbums)
				guard let favorites = session.favorites else {
					view.albums = cache.favoriteAlbums
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				guard let favA = await favorites.albums(order: .dateAdded, orderDirection: .descending) else {
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
}
