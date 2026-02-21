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
		
		workItem = favoriteVideosWI
	}
	
	var favoriteVideosWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			Task {
				var view = TidalSwiftView(viewType: .favoriteVideos)
				guard let favorites = session.favorites else {
					view.videos = cache.favoriteVideos
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				guard let favV = await favorites.videos(order: .dateAdded, orderDirection: .descending) else {
					view.videos = cache.favoriteVideos
					view.loadingState = .error
					replaceCurrentView(with: view)
					return
				}
				
				let t = favV.unwrapped()
				
				view.videos = t
				view.loadingState = .successful
				cache.favoriteVideos = t
				
				replaceCurrentView(with: view)
			}
		}
	}
}
