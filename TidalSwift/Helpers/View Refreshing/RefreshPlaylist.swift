//
//  RefreshPlaylist.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func playlist() {
		guard var view = stack.last else {
			return
		}
		guard let playlist = stack.last?.playlist else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.setPlaylistItems(cache.playlistItems[playlist.id])
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshPlaylist()
		}
	}
	
	private func refreshPlaylist() async {
		guard var view = stack.last else {
			return
		}
		
		guard let playlist = stack.last?.playlist else {
			guard !Task.isCancelled else { return }
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		if let items = await session.playlistItems(playlistId: playlist.id) {
			guard !Task.isCancelled else { return }
			view.setPlaylistItems(items)
			view.loadingState = .successful
			cache.playlistItems[playlist.id] = items
			offline.syncPlaylist(playlist)
		} else {
			view.loadingState = .error
			view.setPlaylistItems(await offline.getItems(for: playlist))
		}
		
		guard !Task.isCancelled else { return }
		replaceCurrentView(with: view)
	}
}

extension TidalSwiftView {
	/// Also sets the tracks, for everything that only plays those
	mutating func setPlaylistItems(_ items: [PlaylistItem]?) {
		playlistItems = items
		tracks = items?.compactMap(\.track)
	}
}
