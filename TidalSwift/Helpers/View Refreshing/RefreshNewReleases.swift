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
		
		workItem = newReleasesWI
	}
	
	// TODO: Proper rework with structured concurrency
	var newReleasesWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			Task {
				let t = await session.helpers.newReleasesFromFavoriteArtists(number: 40, includeEps: newReleasesIncludeEps)
				
				var view = TidalSwiftView(viewType: .newReleases)
				if t != nil {
					view.albums = t
					view.loadingState = .successful
					cache.newReleases = t
				} else {
					view.albums = cache.newReleases
					view.loadingState = .error
				}
				
				replaceCurrentView(with: view)
			}
		}
	}
}
