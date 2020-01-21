//
//  Player.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa
import Foundation
import Combine
import AVFoundation
import TidalSwiftLib

class Player {
	let session: Session
	var autoplayAfterAddNow: Bool
	
	let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	public let queueInfo = QueueInfo()
	
	private var timeObserverToken: Any?
	
	private var previousValue: Float = 1.0
	private var failedItems = 0
	
	private var volumeCancellable: AnyCancellable?
	private var shuffleCancellable: AnyCancellable?
	
	init(session: Session, autoplayAfterAddNow: Bool = true) {
		self.session = session
		self.autoplayAfterAddNow = autoplayAfterAddNow
		
		timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] _ in
			if let s = self {
				s.playbackInfo.fraction = CGFloat(s.fraction())
				s.playbackInfo.playbackTimeInfo = s.playbackTimeInfo()
			}
		}
		
		volumeCancellable = playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: setVolume(to:))
		shuffleCancellable = playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffle(enabled:))
	}
	
	deinit {
		if let token = timeObserverToken {
			avPlayer.removeTimeObserver(token)
			timeObserverToken = nil
		}
		volumeCancellable?.cancel()
		shuffleCancellable?.cancel()
	}
	
	func play() {
		if (!queueInfo.queue.isEmpty) {
//			print("Play: \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
			avPlayer.play()
			playbackInfo.playing = true
			queueInfo.addToHistory(track: queueInfo.queue[queueInfo.currentIndex].track)
		}
	}
	
	func play(atIndex: Int) {
		if queueInfo.queue.count > atIndex {
			queueInfo.currentIndex = atIndex
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex].track)
			play()
		}
	}
	
	func pause() {
		avPlayer.pause()
		playbackInfo.playing = false
		
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
		if avPlayer.currentTime().seconds >= 3 || queueInfo.currentIndex == 0 {
			avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
			if queueInfo.currentIndex == 0 && !queueInfo.queue[queueInfo.currentIndex].track.streamReady {
				print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].track.title)")
				pause()
				next()
			}
			return
		}
		
		queueInfo.currentIndex -= 1
		if queueInfo.queue[queueInfo.currentIndex].track.streamReady {
//			print("previous(): \(playbackInfo.currentIndex) - \(playbackInfo.queue.count)")
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex].track)
//			print("previous() done")
		} else {
			print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].track.title)")
			previous()
		}
	}
	
	func next() {
		if playbackInfo.repeatState == .single {
			seek(to: 0)
			return
		}
		
		if queueInfo.currentIndex >= queueInfo.queue.count - 1 {
//			print("next(): \(playbackInfo.currentIndex) Last - \(playbackInfo.queue.count)")
			if playbackInfo.repeatState == .all {
				queueInfo.currentIndex = 0
			} else {
				pause()
				seek(to: 0)
				return
			}
		} else {
			queueInfo.currentIndex += 1
		}
		if queueInfo.queue[queueInfo.currentIndex].track.streamReady {
//			print("next(): \(playbackInfo.currentIndex) - \(queueCount())")
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex].track)
		} else {
			print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].track.title)")
			next()
		}
	}
	
	func shuffle(enabled: Bool) {
		if queueInfo.queue.isEmpty {
			return
		}
		if enabled {
			queueInfo.nonShuffledQueue = queueInfo.queue
			queueInfo.queue = queueInfo.queue[0...queueInfo.currentIndex] +
				queueInfo.queue[queueInfo.currentIndex+1..<queueInfo.queue.count].shuffled()
			queueInfo.assignQueueIndices()
		} else {
			let i = queueInfo.nonShuffledQueue.firstIndex(where: { $0 == queueInfo.queue[queueInfo.currentIndex] })!
			queueInfo.queue = queueInfo.nonShuffledQueue
			queueInfo.assignQueueIndices()
			queueInfo.currentIndex = i
		}
	}
	
	func seek(to percentage: Double) {
		guard let currentItem = avPlayer.currentItem else {
			return
		}
		let seconds = percentage * currentItem.duration.seconds
		avPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
	}
	
	private func avSetItem(from track: Track) {
//		print("avSetItem(): \(track.title)")
		let wasPlaying = playbackInfo.playing
		pause()
		
		let url: URL
		if let offlineUrl = session.helpers.offline.url(for: track) {
			url = offlineUrl
		} else {
			guard let onlineUrl = track.getAudioUrl(session: session) else {
				failedItems += 1
				if failedItems == queueInfo.queue.count {
					clearQueue()
				} else {
					next()
				}
				return
			}
			url = onlineUrl
		}
		failedItems = 0
		
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
		
		let item = AVPlayerItem(url: url)
		NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		avPlayer.replaceCurrentItem(with: item)
		
		if wasPlaying {
//			print("Was playing...")
			play()
		}
	}
	
	@objc func playerDidFinishPlaying(sender: Notification) {
//		print("Song finished playing")
		next()
	}
	
	func add(playlists: [Playlist], _ when: When) {
		playlists.forEach { playlist in
			add(playlist: playlist, when)
		}
	}
	
	func add(playlist: Playlist, _ when: When) {
		if let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) ?? session.helpers.offline.getTracks(for: playlist) {
			add(tracks: tracks, when)
		}
	}
	
	func add(albums: [Album], _ when: When) {
		albums.forEach { album in
			add(album: album, when)
		}
	}
	
	func add(album: Album, _ when: When) {
		if let tracks = session.getAlbumTracks(albumId: album.id) ?? session.helpers.offline.getTracks(for: album) {
			add(tracks: tracks, when)
		}
	}
	
	func add(artist: Artist, _ when: When) {
		if let tracks = session.getArtistTopTracks(artistId: artist.id) {
			add(tracks: tracks, when)
		}
	}
	
	func add(track: Track, _ when: When) {
		add(tracks: [track], when)
	}
	
	enum When {
		case now
		case next
		case last
	}
	
	func add(tracks: [Track], _ when: When, playAt index: Int = 0) {
		if when == .now {
			addNow(tracks: tracks, playAt: index)
		} else if when == .next {
			addNext(tracks: tracks)
		} else {
			addLast(tracks: tracks)
		}
	}
	
	// playAt is only important when in Shuffle, so only items after the one at the index are shuffled.
	private func addNow(tracks: [Track], playAt index: Int) {
//		print("addNow(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
//		pause()
		clearQueue()
		if playbackInfo.shuffle {
			queueInfo.nonShuffledQueue = tracks.wrapped()
			addLast(tracks: Array(tracks[0...index]))
			if index+1 < tracks.count {
				addLast(tracks: tracks[index+1..<tracks.count].shuffled())
			}
		} else {
			addLast(tracks: tracks)
		}
//		play()
//		print("addNow() finished. Items in Queue: \(playbackInfo.queue.count)")
	}
	
	private func addNext(tracks: [Track]) {
//		print("addNext(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
		queueInfo.nonShuffledQueue.insert(contentsOf: tracks.wrapped(), at: queueInfo.currentIndex)
		let newQueueItems = tracks.wrapped()
		if queueInfo.queue.isEmpty {
			queueInfo.queue.insert(contentsOf: newQueueItems, at: queueInfo.currentIndex)
			avSetItem(from: queueInfo.queue[0].track)
		} else {
			queueInfo.queue.insert(contentsOf: newQueueItems, at: queueInfo.currentIndex + 1)
		}
		queueInfo.assignQueueIndices()
//		print("addNext() finished. Items in Queue: \(queueInfo.queue.count)")
	}
	
	private func addLast(tracks: [Track]) {
//		print("addLast(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
		let wasEmtpy = queueInfo.queue.isEmpty
		
		if !playbackInfo.shuffle {
			queueInfo.nonShuffledQueue.append(contentsOf: tracks.wrapped())
		}
		
		let newQueueItems = tracks.wrapped()
		queueInfo.queue.append(contentsOf: newQueueItems)
		queueInfo.assignQueueIndices()
		if wasEmtpy {
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex].track)
		}
//		print("addLast() finished. Items in Queue: \(queueInfo.queue.count)")
	}
	
	func removeTrack(atIndex: Int) {
		if playbackInfo.shuffle {
			let nonShuffledIndex = queueInfo.nonShuffledQueue.firstIndex(of: queueInfo.queue[atIndex])!
			queueInfo.nonShuffledQueue.remove(at: nonShuffledIndex)
		} else {
			queueInfo.nonShuffledQueue.remove(at: atIndex)
		}
		queueInfo.queue.remove(at: atIndex)
		queueInfo.assignQueueIndices()
		
		if atIndex == queueInfo.currentIndex {
			if queueInfo.queue.count > 0 {
				avSetItem(from: queueInfo.queue[queueInfo.currentIndex].track)
			} else {
				avPlayer.replaceCurrentItem(with: nil)
			}
		}
		
		if atIndex < queueInfo.currentIndex {
			queueInfo.currentIndex -= 1
		}
	}
	
	func clearQueue() {
		avPlayer.pause()
		queueInfo.currentIndex = 0
		avPlayer.replaceCurrentItem(with: nil)
		queueInfo.queue.removeAll()
		queueInfo.nonShuffledQueue.removeAll()
		
		playbackInfo.playing = false
	}
	
	// Clear only items following the current one
	func clearQueueForward() {
		queueInfo.queue.removeLast(queueCount() - queueInfo.currentIndex - 1)
		queueInfo.nonShuffledQueue = queueInfo.queue
	}
	
	func queueCount() -> Int {
		return queueInfo.queue.count
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
		
		var chosenQuality = session.sessionConfig.quality
//		print("\(chosenQuality) \(quality)")
		
		if chosenQuality == .master && quality != .master {
			chosenQuality = .hifi
		}
		if chosenQuality == .hifi && (quality == .high || quality == .low) {
			chosenQuality = .high
		}
		if chosenQuality == .high && quality == .low {
			chosenQuality = .low
		}
		
		return qualityToString(quality: chosenQuality)
	}
	
	func maxQualityString() -> String {
		guard !queueInfo.queue.isEmpty else {
			return ""
		}
		guard let quality = queueInfo.queue[0].track.audioQuality else {
			return ""
		}
		
		return qualityToString(quality: quality)
	}
	
	private func qualityToString(quality: AudioQuality) -> String {
		switch quality {
		case .low:
			return "LOW"
		case .high:
			return "HIGH"
		case .hifi:
			return "HIFI"
		case .master:
			return "MASTER"
		}
	}
}
