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
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshFavoriteAlbums()
		}
	}
	
	private func refreshFavoriteAlbums() async {
		var view = TidalSwiftView(viewType: .favoriteAlbums)
		guard let favorites = session.favorites else {
			guard !Task.isCancelled else { return }
			view.albums = cache.favoriteAlbums
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		guard let favA = await favorites.albums(order: .dateAdded, orderDirection: .descending) else {
			guard !Task.isCancelled else { return }
			view.albums = cache.favoriteAlbums
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		guard !Task.isCancelled else { return }
		let albums = favA.unwrapped()
		
		view.albums = albums
		view.loadingState = .successful
		cache.favoriteAlbums = albums
		
		replaceCurrentView(with: view)
	}
}
