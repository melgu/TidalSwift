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

@MainActor
final class QueueInfo: ObservableObject {

    enum PlaybackMode: Equatable {
        case normal
        case shuffled
        case repeatAll
        case repeatOne
    }

    @Published var playbackMode: PlaybackMode = .normal

	@Published var queue = [WrappedTrack]()
    @Published var normalQueue = [WrappedTrack]()
    @Published var shuffledQueue = [WrappedTrack]()

    /// The queue that should be used for playback based on the current playback mode.
    var activeQueue: [WrappedTrack] {
        switch playbackMode {
        case .normal, .repeatAll, .repeatOne:
            return normalQueue
        case .shuffled:
            return shuffledQueue
        }
    }

    /// Rotates the given wrapped-track array so that the provided track (by equality) is at index 0, preserving order of the remainder.
    private func rotatedPuttingCurrentFirst(array: [WrappedTrack], currentTrack: Track?) -> [WrappedTrack] {
        guard let currentTrack else { return array }
        guard let idx = array.firstIndex(where: { $0.track == currentTrack }) else { return array }
        if idx == 0 { return array }
        let head = Array(array[idx...])
        let tail = Array(array[..<idx])
        return head + tail
    }

    private func updateQueuesFromNormal() {
        // Determine the currently playing track (from the visible queue head if available)
        let currentTrack = queue.first?.track ?? normalQueue.first?.track

        // Build a shuffled variant that keeps the current track at the top and shuffles the remainder from normalQueue
        var shuffled: [WrappedTrack]
        if let currentTrack {
            let remainder = normalQueue.filter { $0.track != currentTrack }
            var rest = remainder
            rest.shuffle()
            // Place the current track first if it exists in normalQueue; otherwise just use shuffled remainder
            if let currentWrapped = normalQueue.first(where: { $0.track == currentTrack }) {
                shuffled = [currentWrapped] + rest
            } else {
                shuffled = rest
            }
        } else {
            // No current track yet; shuffle entire normalQueue keeping the first element as top to be stable
            if var temp = normalQueue as [WrappedTrack]? {
                if !temp.isEmpty {
                    let top = temp.removeFirst()
                    temp.shuffle()
                    shuffled = [top] + temp
                } else {
                    shuffled = []
                }
            } else {
                shuffled = []
            }
        }

        // Assign to stored shuffledQueue
        shuffledQueue = shuffled

        // Choose the base list by mode
        let base: [WrappedTrack]
        switch playbackMode {
        case .shuffled:
            base = shuffledQueue
        case .normal, .repeatAll, .repeatOne:
            base = normalQueue
        }

        // Rotate so the current track is at index 0
        let rotated = rotatedPuttingCurrentFirst(array: base, currentTrack: currentTrack)

        // Update the visible queue only if changed
        if queue.map({ $0.track.id }) != rotated.map({ $0.track.id }) {
            queue = rotated
        }
    }

    init(){
        self.$normalQueue
                    .sink { [weak self] _ in
                        self?.updateQueuesFromNormal()
                    }
                    .store(in: &subscribers)
        
    }
	@Published var history: [WrappedTrack] = []

    // MARK: - Playback mode controls
    func setPlaybackMode(_ mode: PlaybackMode) {
        let current = currentItem?.track
        playbackMode = mode
        // Recompute queues while keeping current on top
        updateQueuesFromNormal()
        // Ensure current remains on top after mode switch
        if let current {
            queue = rotatedPuttingCurrentFirst(array: queue, currentTrack: current)
        }
    }

    func toggleShuffle() {
        setPlaybackMode((playbackMode == .shuffled) ? .normal : .shuffled)
    }

    func toggleRepeatAll() {
        setPlaybackMode((playbackMode == .repeatAll) ? .normal : .repeatAll)
    }

    func toggleRepeatOne() {
        setPlaybackMode((playbackMode == .repeatOne) ? .normal : .repeatOne)
    }

	var maxHistoryItems: Int = 100
    private var subscribers = Set<AnyCancellable>()
	var currentItem: WrappedTrack? {
        
		queue.element(at:0)
	}
    var currentItemShuffled: WrappedTrack? {
        
        shuffledQueue.element(at:0)
    }

    // Returns the current index in the active queue, if present
    private func currentIndex() -> Int? {
        guard let current = currentItem else { return nil }
        return activeQueue.firstIndex(where: { $0.track == current.track })
    }

    func nextTrack() {
        guard !queue.isEmpty else { return }
        switch playbackMode {
        case .repeatOne:
            return
        case .shuffled, .normal, .repeatAll:
            let finished = queue.removeFirst()
            history.append(finished)
            if queue.isEmpty {
                if playbackMode == .repeatAll {
                    // Wrap to the beginning of the base list without extra rotation
                    let base: [WrappedTrack] = (playbackMode == .shuffled) ? shuffledQueue : normalQueue
                    if !base.isEmpty {
                        queue = base
                    }
                }
            }
        }
    }

    func previousTrack() {
        guard !queue.isEmpty else { return }
        switch playbackMode {
        case .repeatOne:
            return
        case .shuffled, .normal, .repeatAll:
            if let last = history.popLast() {
                queue.insert(last, at: 0)
            } else if playbackMode == .repeatAll {
                let base: [WrappedTrack] = (playbackMode == .shuffled) ? shuffledQueue : normalQueue
                if !base.isEmpty {
                    queue = base
                }
            }
        }
    }
	
	func assignQueueIndices() {
        // No-op: indices are derived from position or stable track identifiers.
        // Keeping this method for compatibility; avoid rewriting the arrays to prevent large copies.
	}
	
	func addToHistory(track: Track) {
		// Ensure Track only exists once in History
		history.removeAll(where: { $0.track == track })
		
		history.append(WrappedTrack(id: 0, track: track))
		
		// Enforce Maximum
		if history.count >= maxHistoryItems {
			history.removeFirst(history.count - maxHistoryItems)
		}
		
		assignHistoryIndices()
	}
	
	func assignHistoryIndices() {
		for i in 0..<history.count {
			history[i] = WrappedTrack(id: i, track: history[i].track)
		}
	}
	
	func clearHistory() {
		history.removeAll()
	}
    
    // MARK: - Lightweight ID-based helpers

    /// Returns a lightweight representation of the queue using stable track identifiers.
    /// This avoids persisting heavy data and allows reconstructing the queue later.
    func queueTrackIDs(idProvider: (Track) -> String) -> [String] {
        queue.map { idProvider($0.track) }
    }

    /// Rebuilds the queue from stable track identifiers using a resolver that can find tracks by ID.
    /// - Parameters:
    ///   - ids: The ordered list of track identifiers.
    ///   - resolver: A closure that returns a Track for a given identifier.
    func rebuildQueue(from ids: [String], resolver: (String) -> Track?) {
        let tracks = ids.compactMap { resolver($0) }
        self.queue = tracks.map { WrappedTrack(id: 0, track: $0) }
        // No need to assign indices; prefer using stable track IDs in SwiftUI ForEach.
        
    }
}

