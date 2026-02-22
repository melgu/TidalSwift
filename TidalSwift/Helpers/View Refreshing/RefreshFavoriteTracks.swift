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
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshFavoriteTracks()
		}
	}
	
	private func refreshFavoriteTracks() async {
		var view = TidalSwiftView(viewType: .favoriteTracks)
		guard let favorites = session.favorites else {
			guard !Task.isCancelled else { return }
			view.tracks = cache.favoriteTracks
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		guard let favT = await favorites.tracks(order: .dateAdded, orderDirection: .descending) else {
			guard !Task.isCancelled else { return }
			view.tracks = cache.favoriteTracks
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		guard !Task.isCancelled else { return }
		let tracks = favT.unwrapped()
		
		view.tracks = tracks
		view.loadingState = .successful
		cache.favoriteTracks = tracks
		
		session.helpers.offline.asyncSyncFavoriteTracks()
		replaceCurrentView(with: view)
	}
}
