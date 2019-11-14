//
//  PlaybackInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

final class PlaybackInfo: ObservableObject {
	var nonShuffledQueue = [Track]()
	@Published var queue = [QueueItem]()
	@Published var currentIndex: Int = 0
	@Published var fraction: CGFloat = 0.0
	@Published var playing: Bool = false
	@Published var volume: Float = 1.0
	@Published var shuffle: Bool = false
	@Published var repeatState: RepeatState = .off
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
	var nonShuffledQueue: [Track]
	var queue: [QueueItem]
	var currentIndex: Int
	var fraction: CGFloat
	var playing: Bool
	var volume: Float
	var shuffle: Bool
	var repeatState: RepeatState
}
