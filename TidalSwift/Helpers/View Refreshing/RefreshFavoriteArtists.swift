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
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshFavoriteArtists()
		}
	}
	
	private func refreshFavoriteArtists() async {
		var view = TidalSwiftView(viewType: .favoriteArtists)
		guard let favorites = session.favorites else {
			guard !Task.isCancelled else { return }
			view.artists = cache.favoriteArtists
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		guard let favA = await favorites.artists(order: .dateAdded, orderDirection: .descending) else {
			guard !Task.isCancelled else { return }
			view.artists = cache.favoriteArtists
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		guard !Task.isCancelled else { return }
		let artists = favA.unwrapped()
		
		view.artists = artists
		view.loadingState = .successful
		cache.favoriteArtists = artists
		
		replaceCurrentView(with: view)
	}
}
