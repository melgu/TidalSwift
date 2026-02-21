//
//  RefreshMyMixes.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func myMixes() {
		var view = TidalSwiftView(viewType: .myMixes)
		view.mixes = cache.mixes
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = myMixesWI
	}
	
	var myMixesWI: DispatchWorkItem {
		DispatchWorkItem { [self] in
			Task {
				let t = await session.mixes()
				
				var view = TidalSwiftView(viewType: .myMixes)
				if t != nil {
					view.mixes = t
					view.loadingState = .successful
					cache.mixes = t
				} else {
					view.mixes = cache.mixes
					view.loadingState = .error
				}
				
				replaceCurrentView(with: view)
			}
		}
	}
}
