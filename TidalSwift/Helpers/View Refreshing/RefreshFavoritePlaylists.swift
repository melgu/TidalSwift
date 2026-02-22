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
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshFavoritePlaylists()
		}
	}
	
	private func refreshFavoritePlaylists() async {
		var view = TidalSwiftView(viewType: .favoritePlaylists)
		guard let favorites = session.favorites else {
			guard !Task.isCancelled else { return }
			view.playlists = cache.favoritePlaylists
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		guard let favP = await favorites.playlists(order: .dateAdded, orderDirection: .descending) else {
			guard !Task.isCancelled else { return }
			view.playlists = cache.favoritePlaylists
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		guard !Task.isCancelled else { return }
		let playlists = favP.unwrapped()
		
		view.playlists = playlists
		view.loadingState = .successful
		cache.favoritePlaylists = playlists
		
		replaceCurrentView(with: view)
	}
}
