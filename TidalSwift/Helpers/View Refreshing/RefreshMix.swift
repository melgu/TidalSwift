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
		
		workItem = mixWI
	}
	
	var mixWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			guard var view = stack.last else {
				return
			}
			
			var t: [Track]?
			if let mix = view.mix {
				t = session.getMixPlaylistTracks(mixId: mix.id)
				
				if t != nil {
					view.tracks = t
					view.loadingState = .successful
					cache.mixTracks[mix.id] = t
				} else {
					if let mixId = view.mix?.id {
						view.tracks = cache.mixTracks[mixId]
					}
					view.loadingState = .error
				}
				
				replaceCurrentView(with: view)
			}
		}
	}
}
