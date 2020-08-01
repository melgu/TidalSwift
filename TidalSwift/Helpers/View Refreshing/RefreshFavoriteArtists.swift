//
//  RefreshFavoriteArtists.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

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
