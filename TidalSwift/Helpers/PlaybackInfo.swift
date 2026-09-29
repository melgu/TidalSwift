//
//  PlaybackInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

@Observable
final class PlaybackInfo {
	var fraction: CGFloat = 0.0
	var playbackTimeInfo: String = "0:00 / 0:00"
	var playing: Bool = false
	var volume: Float = 1.0 {
		didSet {
			hasUnsavedChanges = true
			onVolumeChange?(volume)
		}
	}
	var shuffle: Bool = false {
		didSet {
			hasUnsavedChanges = true
			onShuffleChange?(shuffle)
		}
	}
	var repeatState: RepeatState = .off { didSet { hasUnsavedChanges = true } }
	var pauseAfter: Bool = false { didSet { hasUnsavedChanges = true } }
	
	@ObservationIgnored var hasUnsavedChanges = false
	
	@ObservationIgnored var onVolumeChange: ((Float) -> Void)?
	@ObservationIgnored var onShuffleChange: ((Bool) -> Void)?
}

enum RepeatState: Int, CaseIterable, Codable {
	case off
	case all
	case single
}

extension CaseIterable where Self: Equatable {
	func next() -> Self {
		let all = Self.allCases
		let idx = all.firstIndex(of: self)!
		let next = all.index(after: idx)
		return all[next == all.endIndex ? all.startIndex : next]
	}
}

struct CodablePlaybackInfo: Codable {
	// PlaybackInfo
	var fraction: CGFloat
	var volume: Float
	var shuffle: Bool
	var repeatState: RepeatState
	var pauseAfter: Bool
	
	// QueueInfo
	var nonShuffledQueue: [Track]
	var queue: [Track]
	var currentIndex: Int
	
	var history: [Track]
	var maxHistoryItems: Int
}
