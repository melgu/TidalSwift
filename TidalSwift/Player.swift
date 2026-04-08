//
//  Player.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
@preconcurrency import Combine
import AVFoundation
import TidalSwiftLib

class Player {
	let session: Session
	var autoplayAfterAddNow: Bool
	
	let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	public let queueInfo = QueueInfo()
    private var currentlyPlayingTrack:Track? = nil
	private var timeObserverToken: Any?
	
	private var previousValue: Float = 1.0
	private var failedItems = 0
	
	private var volumeCancellable: AnyCancellable?
	private var shuffleCancellable: AnyCancellable?
    private var repeatCancellable: AnyCancellable?
	
	private var currentAudioQuality: AudioQuality
	private(set) var nextAudioQuality: AudioQuality
    public func getCurrentlyPlayingTrack() -> Track?{
        
        return currentlyPlayingTrack;
    }
	init(session: Session, audioQuality: AudioQuality, autoplayAfterAddNow: Bool = true) {
		self.session = session
		self.currentAudioQuality = audioQuality
		self.nextAudioQuality = audioQuality
		self.autoplayAfterAddNow = autoplayAfterAddNow
		
		timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] _ in
			if let self {
				Task { @MainActor in
					self.playbackInfo.fraction = CGFloat(self.fraction())
					self.playbackInfo.playbackTimeInfo = self.playbackTimeInfo()
				}
			}
		}
		
		volumeCancellable = playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: setVolume(to:))
        shuffleCancellable = playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink { [weak self] isOn in
            guard let self else { return }
            if isOn {
                self.queueInfo.setPlaybackMode(.shuffled)
            } else {
                // Preserve repeat mode when turning shuffle off
                switch self.queueInfo.playbackMode {
                case .repeatOne:
                    self.queueInfo.setPlaybackMode(.repeatOne)
                case .repeatAll:
                    self.queueInfo.setPlaybackMode(.repeatAll)
                default:
                    self.queueInfo.setPlaybackMode(.normal)
                }
            }
        }
        repeatCancellable = playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink { [weak self] state in
            guard let self else { return }
            switch state {
            case .off:
                // If shuffle is on, prefer shuffled; otherwise normal
                if self.playbackInfo.shuffle {
                    self.queueInfo.setPlaybackMode(.shuffled)
                } else {
                    self.queueInfo.setPlaybackMode(.normal)
                }
            case .all:
                // Repeat all respects shuffle setting
                if self.playbackInfo.shuffle {
                    self.queueInfo.setPlaybackMode(.shuffled)
                } else {
                    self.queueInfo.setPlaybackMode(.repeatAll)
                }
            case .single:
                self.queueInfo.setPlaybackMode(.repeatOne)
            }
        }
	}
	
	@MainActor
	deinit {
		if let token = timeObserverToken {
			avPlayer.removeTimeObserver(token)
			timeObserverToken = nil
		}
		volumeCancellable?.cancel()
		shuffleCancellable?.cancel()
        repeatCancellable?.cancel()
	}
	
	func setAudioQuality(to audioQuality: AudioQuality) {
		nextAudioQuality = audioQuality
	}
	
	func play() {
	    guard let _ = queueInfo.queue.first else { return }
	    Task { @MainActor in
	        playbackInfo.playing = true
	        avPlayer.play()
	    }
	}
	
	func play(atIndex index: Int) {
	    // Ensure index is valid
	    guard index >= 0, index < queueInfo.queue.count else { return }

	    // Rotate the queue so that the selected index becomes the first element
	    if index > 0 {
	        let head = Array(queueInfo.queue[index...])
	        let tail = Array(queueInfo.queue[..<index])
	        queueInfo.queue = head + tail
	    }

	    // Now the selected item is first; mark intent and set item
	    guard let current = queueInfo.queue.first else { return }
	    Task { @MainActor in
	        avSetItem(from: current.track)
	        playbackInfo.playing = true
	    }
	}
	
	func pause() {
	    Task { @MainActor in
	        playbackInfo.playing = false
	        avPlayer.pause()
	    }
	}
	
	func togglePlay() {
		if playbackInfo.playing {
			pause()
		} else {
			play()
		}
	}
	
	func stop() {
		pause()
		seek(to: 0)
	}
	
    func previous() {
        // Move back according to the current playback mode
        queueInfo.previousTrack()
        guard let current = queueInfo.queue.first else { return }
        Task { @MainActor in
            currentlyPlayingTrack = current.track
            avSetItem(from: current.track)
            avPlayer.play()
            playbackInfo.playing = true
        }
    }
	
	func next() {
        // Move the queue head according to the current playback mode
        queueInfo.nextTrack()
        // Play new first if available
        guard let nextUp = queueInfo.queue.first else {
            Task { @MainActor in
                playbackInfo.playing = false
            }
            return
        }
        Task { @MainActor in
            currentlyPlayingTrack = nextUp.track
            avSetItem(from: nextUp.track)
            avPlayer.play()
            playbackInfo.playing = true
        }
    }
	
	func shuffle(enabled: Bool) {
       
        
	}
	
	func seek(to percentage: Double) {
		guard let currentItem = avPlayer.currentItem else {
			return
		}
		let seconds = percentage * currentItem.duration.seconds
		avPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
	}
	
	private func internalPause() {
		avPlayer.pause()
	}
	
	private func avSetItem(from track: Track) {
		Task {
			await avSetItemAsync(from: track)
		}
	}
	
	private func avSetItemAsync(from track: Track) async {
//		print("avSetItem(): \(track.title)")
		let wasPlaying = playbackInfo.playing
		internalPause()
		
		func skip() {
			failedItems += 1
			if failedItems == queueInfo.queue.count {
				clearQueue()
			} else {
				next()
			}
		}
		
		if track.isUnavailable {
			skip()
			return
		}
		
		let url: URL
		if let offlineUrl = await session.helpers.offline.url(for: track, audioQuality: nextAudioQuality) {
			
			url = offlineUrl
		} else {
			if let onlineUrl = await track.audioUrl(session: session, audioQuality: nextAudioQuality) {
				url = onlineUrl
				
			} else {
				
				skip()
				return
			}
		}
		failedItems = 0
		
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
		
		let item = AVPlayerItem(url: url)
		NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		avPlayer.replaceCurrentItem(with: item)
		
		currentAudioQuality = nextAudioQuality
		
		if wasPlaying || playbackInfo.playing {
			await MainActor.run {
				avPlayer.play()
				playbackInfo.playing = true
			}
		}
	}
	
	@objc func playerDidFinishPlaying(sender: Notification) {
//		
		next()
	}
	
	func add(playlists: [Playlist], _ when: When) {
        
            playlists.forEach{ playlist in
                add(playlist: playlist, when)
            }
        
	}
	
	func add(playlist: Playlist, _ when: When) {
        Task {
                    let apiTracks = await session.playlistTracks(playlistId: playlist.uuid)
                    let offlineTracks = await session.helpers.offline.getTracks(for: playlist)
                    if let tracks = apiTracks ?? offlineTracks {
                        add(tracks: tracks, when)
                    }
        }
	}
	
	func add(albums: [Album], _ when: When) {
        albums.forEach { album in
                    add(album: album, when)
                }
	}
	
	func add(album: Album, _ when: When) {
        Task {
                    let apiTracks = await session.albumTracks(albumId: album.id)
                    let offlineTracks = await session.helpers.offline.getTracks(for: album)
                    if let tracks = apiTracks ?? offlineTracks {
                        add(tracks: tracks, when)
                    } else if when == .now {
                        clearQueue()
                    }
                }
	}
	
	func add(artist: Artist, _ when: When) {
        Task {
                    if let tracks = await session.artistTopTracks(artistId: artist.id) {
                        add(tracks: tracks, when)
                    }
                }
	}
    func add(tracks: [Track], _ when:When){
        switch when {
        case .now:
            addNow(tracks: tracks)
        case .next:
            addNext(tracks: tracks)
        case .last:
            addLast(tracks: tracks)
        }
        queueInfo.assignQueueIndices()
    }
	func add(track: Track, _ when: When) {
        switch when {
        case .now:
            addNow(tracks: [track])
        case .next:
            addNext(tracks: [track])
        case .last:
            addLast(tracks: [track])
        }
        queueInfo.assignQueueIndices()
	}
	
	enum When {
		case now
		case next
		case last
	}
	
	
	
	// playAt is only important when in Shuffle, so only items after the one at the index are shuffled.
	private func addNow(tracks: [Track]) {
        // Insert at the front of the normal queue (source of truth)
        queueInfo.normalQueue.insert(contentsOf: tracks.map { .init(id: $0.id, track: $0) }, at: 0)
        // Propagate to active queue based on current mode
        queueInfo.setPlaybackMode(queueInfo.playbackMode)
        if let current = queueInfo.queue.first {
            currentlyPlayingTrack = current.track
            avSetItem(from: current.track)
        }
	}
	
	private func addNext(tracks: [Track]) {
        let items = tracks.map { WrappedTrack(id: $0.id, track: $0) }
        if queueInfo.normalQueue.isEmpty {
            queueInfo.normalQueue.append(contentsOf: items)
        } else {
            queueInfo.normalQueue.insert(contentsOf: items, at: min(1, queueInfo.normalQueue.count))
        }
        queueInfo.setPlaybackMode(queueInfo.playbackMode)
	}
	
	private func addLast(tracks: [Track]) {
        queueInfo.normalQueue.append(contentsOf: tracks.map{ .init(id: $0.id, track: $0) })
        queueInfo.setPlaybackMode(queueInfo.playbackMode)
	}
	
	func removeTrack(atIndex: Int) {
        guard atIndex >= 0 && atIndex < queueInfo.normalQueue.count else { return }
        queueInfo.normalQueue.remove(at: atIndex)
        queueInfo.setPlaybackMode(queueInfo.playbackMode)
	}
	
	func clearQueue(leavingCurrent: Bool = false) {
        pause()
        queueInfo.normalQueue.removeAll()
        queueInfo.setPlaybackMode(queueInfo.playbackMode)
        Task { @MainActor in
            avPlayer.replaceCurrentItem(with: nil)
        }
	}
	
	func queueCount() -> Int {
		queueInfo.queue.count
	}
	
	func fraction() -> Double {
		guard let totalTime = avPlayer.currentItem?.duration.seconds else {
			return 0
		}
		guard !totalTime.isNaN else {
			return 0
		}
		
		let r = avPlayer.currentTime().seconds / totalTime
//		print("fraction(): r: \(r), currentTime: \(avPlayer.currentTime().seconds), totalTime: \(totalTime)")
		
		return r
	}
	
	func playbackTimeInfo() -> String {
		guard let totalTime = avPlayer.currentItem?.duration.seconds else {
			return ""
		}
		guard !totalTime.isNaN else {
			return ""
		}
		
		let currentTimeString = secondsToHoursMinutesSecondsString(seconds: Int(avPlayer.currentTime().seconds))
		let totalTimeString = secondsToHoursMinutesSecondsString(seconds: Int(totalTime))
		return "\(currentTimeString) / \(totalTimeString)"
	}
	
	func setVolume(to volume: Float) {
		avPlayer.volume = volume
	}
	
	func increaseVolume() {
		var newVolume = playbackInfo.volume + 0.1
		if newVolume > 1 {
			newVolume = 1
		}
		playbackInfo.volume = newVolume
	}
	
	func decreaseVolume() {
		var newVolume = playbackInfo.volume - 0.1
		if newVolume < 0 {
			newVolume = 0
		}
		playbackInfo.volume = newVolume
	}
	
	func toggleMute() {
		if playbackInfo.volume == 0 {
			playbackInfo.volume = previousValue
		} else {
			previousValue = playbackInfo.volume
			playbackInfo.volume = 0
		}
	}
	
	func currentQualityString() -> String {
        guard !queueInfo.queue.isEmpty else {
                    return ""
                }
                guard let quality = queueInfo.queue[0].track.audioQuality else {
                    return ""
                }
                
                var chosenQuality = currentAudioQuality
        //        print("\(chosenQuality) \(quality)")
                
                if chosenQuality == .max && quality != .max {
                    chosenQuality = .high
                }
                if chosenQuality == .high && (quality == .medium || quality == .low) {
                    chosenQuality = .medium
                }
                if chosenQuality == .medium && quality == .low {
                    chosenQuality = .low
                }
                
                return qualityToString(quality: chosenQuality)
	}
	
	func maxQualityString() -> String {
		guard !queueInfo.queue.isEmpty else {
			return ""
		}
		return qualityToString(quality: nextAudioQuality)
	}
	
	private func qualityToString(quality: AudioQuality) -> String {
		switch quality {
		case .low:
			return "LOW"
		case .medium:
			return "HIGH"
		case .high:
			return "HIFI"
		case .max:
			return "MASTER"
		}
	}
}

