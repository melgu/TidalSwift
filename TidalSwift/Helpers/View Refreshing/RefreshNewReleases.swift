//
//  RefreshNewReleases.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func newReleases() {
		var view = TidalSwiftView(viewType: .newReleases)
		view.albums = cache.newReleases
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshNewReleases()
		}
	}
	
	func refreshNewReleases() async {
		let albums = await session.helpers.newReleasesFromFavoriteArtists(number: 40, includeEps: newReleasesIncludeEps)
		
		guard !Task.isCancelled else { return }
		var view = TidalSwiftView(viewType: .newReleases)
		if albums != nil {
			view.albums = albums
			view.loadingState = .successful
			cache.newReleases = albums
		} else {
			view.albums = cache.newReleases
			view.loadingState = .error
		}
		
		replaceCurrentView(with: view)
	}
}
