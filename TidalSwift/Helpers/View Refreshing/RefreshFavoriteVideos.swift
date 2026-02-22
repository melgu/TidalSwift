//
//  RefreshFavoriteVideos.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func favoriteVideos() {
		var view = TidalSwiftView(viewType: .favoriteVideos)
		view.videos = cache.favoriteVideos
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshFavoriteVideos()
		}
	}
	
	private func refreshFavoriteVideos() async {
		var view = TidalSwiftView(viewType: .favoriteVideos)
		guard let favorites = session.favorites else {
			guard !Task.isCancelled else { return }
			view.videos = cache.favoriteVideos
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		guard let favV = await favorites.videos(order: .dateAdded, orderDirection: .descending) else {
			guard !Task.isCancelled else { return }
			view.videos = cache.favoriteVideos
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		guard !Task.isCancelled else { return }
		let videos = favV.unwrapped()
		
		view.videos = videos
		view.loadingState = .successful
		cache.favoriteVideos = videos
		
		replaceCurrentView(with: view)
	}
}
