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
	
	var newReleasesWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			let t = session.helpers.newReleasesFromFavoriteArtists(number: 40, includeEps: newReleasesIncludeEps)
			
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
