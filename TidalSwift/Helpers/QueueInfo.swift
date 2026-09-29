//
//  QueueInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

@Observable
final class QueueInfo {
	@ObservationIgnored var nonShuffledQueue = [Track]()
	var queue = [Track]() {
		didSet {
			hasUnsavedChanges = true
			onCurrentTrackChange?()
		}
	}
	var currentIndex: Int = 0 {
		didSet {
			hasUnsavedChanges = true
			onCurrentTrackChange?()
		}
	}
	
	var history: [Track] = []
	@ObservationIgnored var maxHistoryItems: Int = 100
	
	@ObservationIgnored var hasUnsavedChanges = false
	
	@ObservationIgnored var onCurrentTrackChange: (() -> Void)?
	
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
