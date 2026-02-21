//
//  PlaybackInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

@MainActor
final class PlaybackInfo: ObservableObject {
	@Published var fraction: CGFloat = 0.0
	@Published var playbackTimeInfo: String = "0:00 / 0:00"
	@Published var playing: Bool = false
	@Published var volume: Float = 1.0
	@Published var shuffle: Bool = false
	@Published var repeatState: RepeatState = .off
	@Published var pauseAfter: Bool = false
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
	var nonShuffledQueue: [WrappedTrack]
	var queue: [WrappedTrack]
	var currentIndex: Int
	
	var history: [WrappedTrack]
	var maxHistoryItems: Int
}
