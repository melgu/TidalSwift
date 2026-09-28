//
//  QueueInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import Combine
import TidalSwiftLib

final class QueueInfo: ObservableObject {
	var nonShuffledQueue = [Track]()
	@Published var queue = [Track]()
	@Published var currentIndex: Int = 0
	
	@Published var history: [Track] = []
	var maxHistoryItems: Int = 100
	
	var currentItem: Track? {
		queue.element(at: currentIndex)
	}
	
	func addToHistory(track: Track) {
		// Ensure Track only exists once in History
		history.removeAll(where: { $0 == track })
		
		history.append(track)
		
		// Enforce Maximum
		if history.count >= maxHistoryItems {
			history.removeFirst(history.count - maxHistoryItems)
		}
	}
	
	func clearHistory() {
		history.removeAll()
	}
}
