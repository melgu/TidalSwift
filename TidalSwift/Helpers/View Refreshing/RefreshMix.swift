//
//  RefreshMix.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func mix() {
		guard var view = stack.last else {
			return
		}
		guard let mixId = view.mix?.id else {
			view.loadingState = .error
			replaceCurrentView(with: view)
			return
		}
		
		view.tracks = cache.mixTracks[mixId]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshMix()
		}
	}
	
	private func refreshMix() async {
		guard var view = stack.last else {
			return
		}
		
		guard let mix = view.mix else {
			return
		}
		
		let tracks = await session.mixPlaylistTracks(mixId: mix.id)
		
		guard !Task.isCancelled else { return }
		if tracks != nil {
			view.tracks = tracks
			view.loadingState = .successful
			cache.mixTracks[mix.id] = tracks
		} else {
			if let mixId = view.mix?.id {
				view.tracks = cache.mixTracks[mixId]
			}
			view.loadingState = .error
		}
		
		replaceCurrentView(with: view)
	}
}
