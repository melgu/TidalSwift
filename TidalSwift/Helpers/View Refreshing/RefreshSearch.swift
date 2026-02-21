//
//  RefreshSearch.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension ViewState {
	func search() {
		guard var view = stack.last else {
			return
		}
		
		view.searchResponse = cache.searchResponses[searchTerm]
		view.loadingState = .loading
		replaceCurrentView(with: view)
		
		workItem = searchWI(searchTerm: searchTerm)
	}
	
	func doSearch(term: String) {
		if stack.last?.viewType != .search {
			return
		}
		if searchTerm == lastSearchTerm || searchTerm.isEmpty {
			return
		}
		lastSearchTerm = searchTerm
		workItem?.cancel()
		
		search()
		DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
	}
	
	func searchWI(searchTerm: String) -> DispatchWorkItem {
		DispatchWorkItem { [self] in
			Task {
				let t = await session.search(for: searchTerm)
				
				var view = TidalSwiftView(viewType: .search)
				if t != nil {
					view.searchResponse = t
					view.loadingState = .successful
					cache.searchResponses[searchTerm] = t
				} else {
					view.searchResponse = cache.searchResponses[searchTerm]
					view.loadingState = .error
				}
				
				replaceCurrentView(with: view)
			}
		}
	}
}
