//
//  RefreshAlbum.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func album() {
		guard var view = stack.last else {
			return
		}
		guard let album = stack.last?.album else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.albumTracks[album.id]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshAlbum()
		}
	}
	
	private func refreshAlbum() async {
		guard var view = stack.last else {
			return
		}
		
		guard let album = stack.last?.album else {
			guard !Task.isCancelled else { return }
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		if album.releaseDate == nil {
			print("Album incomplete. Loading complete album: \(album.title)")
			if let tAlbum = await session.album(albumId: album.id) {
				guard !Task.isCancelled else { return }
				view.album = tAlbum
			} else {
				guard !Task.isCancelled else { return }
				view.loadingState = .error
				replaceCurrentView(with: view)
				return
			}
		}
		
		view.tracks = await session.albumTracks(albumId: album.id)
		
		if view.tracks != nil {
			guard !Task.isCancelled else { return }
			view.loadingState = .successful
			cache.albumTracks[album.id] = view.tracks
		} else {
			view.loadingState = .error
			view.tracks = await session.helpers.offline.getTracks(for: album)
		}
		
		guard !Task.isCancelled else { return }
		replaceCurrentView(with: view)
	}
}
