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
		
		let term = searchTerm
		refreshTask?.cancel()
		refreshTask = Task { [self] in
			await refreshSearch(searchTerm: term)
		}
	}
	
	func doSearch(term: String) {
		if stack.last?.viewType != .search {
			return
		}
		if searchTerm == lastSearchTerm || searchTerm.isEmpty {
			return
		}
		lastSearchTerm = searchTerm
		refreshTask?.cancel()
		
		search()
	}
	
	private func refreshSearch(searchTerm: String) async {
		let response = await session.search(for: searchTerm)
		
		guard !Task.isCancelled else { return }
		var view = TidalSwiftView(viewType: .search)
		if response != nil {
			view.searchResponse = response
			view.loadingState = .successful
			cache.searchResponses[searchTerm] = response
		} else {
			view.searchResponse = cache.searchResponses[searchTerm]
			view.loadingState = .error
		}
		
		replaceCurrentView(with: view)
	}
}
