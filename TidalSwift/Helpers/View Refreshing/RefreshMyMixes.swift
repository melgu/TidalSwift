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
		
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshMyMixes()
		}
	}
	
	private func refreshMyMixes() async {
		let mixes = await session.mixes()
		
		guard !Task.isCancelled else { return }
		var view = TidalSwiftView(viewType: .myMixes)
		if mixes != nil {
			view.mixes = mixes
			view.loadingState = .successful
			cache.mixes = mixes
		} else {
			view.mixes = cache.mixes
			view.loadingState = .error
		}
		
		replaceCurrentView(with: view)
	}
}
