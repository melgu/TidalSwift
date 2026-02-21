//
//  RefreshOffline.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func offlinePlaylists() {
		guard var view = stack.last else {
			return
		}
		Task {
			view.playlists = await session.helpers.offline.allOfflinePlaylists()
			view.loadingState = .successful
			replaceCurrentView(with: view)
		}
	}
	
	func offlineAlbums() {
		guard var view = stack.last else {
			return
		}
		Task {
			view.albums = await session.helpers.offline.allOfflineAlbums()
			view.loadingState = .successful
			replaceCurrentView(with: view)
		}
	}
	
	func offlineTracks() {
		guard var view = stack.last else {
			return
		}
		Task {
			view.tracks = await session.helpers.offline.allOfflineTracks()
			view.loadingState = .successful
			replaceCurrentView(with: view)
		}
	}
}
