//
//  Player.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation
import TidalSwiftLib

class Player {
	let session: Session
	var autoplayAfterAddNow: Bool
	
	let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	
	private var timeObserverToken: Any?
	
	private var previousValue: Float = 1.0
	private var failedItems = 0
	
	init(session: Session, autoplayAfterAddNow: Bool = true) {
		self.session = session
		self.autoplayAfterAddNow = autoplayAfterAddNow
		
		timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			self?.playbackInfo.fraction = CGFloat(self!.fraction())
		}
		
		_ = playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: setVolume(to:))
		_ = playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffle(enabled:))
	}
	
	deinit {
		if let token = timeObserverToken {
			avPlayer.removeTimeObserver(token)
			timeObserverToken = nil
		}
	}
	
	func play() {
		if (!playbackInfo.queue.isEmpty) {
//			print("Play: \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
			avPlayer.play()
			playbackInfo.playing = true
			playbackInfo.addToHistory(track: playbackInfo.queue[playbackInfo.currentIndex].track)
		}
	}
	
	func play(atIndex: Int) {
		if playbackInfo.queue.count > atIndex {
			playbackInfo.currentIndex = atIndex
			avSetItem(from: playbackInfo.queue[playbackInfo.currentIndex].track)
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
		if avPlayer.currentTime().seconds >= 3 || playbackInfo.currentIndex == 0 {
			avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
			if playbackInfo.currentIndex == 0 && !playbackInfo.queue[playbackInfo.currentIndex].track.streamReady {
				print("Not possible to stream \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
				pause()
				next()
			}
			return
		}
		
		playbackInfo.currentIndex -= 1
		if playbackInfo.queue[playbackInfo.currentIndex].track.streamReady {
//			print("previous(): \(playbackInfo.currentIndex) - \(playbackInfo.queue.count)")
			avSetItem(from: playbackInfo.queue[playbackInfo.currentIndex].track)
//			print("previous() done")
		} else {
			print("Not possible to stream \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
			previous()
		}
	}
	
	func next() {
		if playbackInfo.repeatState == .single {
			seek(to: 0)
			return
		}
		
		if playbackInfo.currentIndex >= playbackInfo.queue.count - 1 {
//			print("next(): \(playbackInfo.currentIndex) Last - \(playbackInfo.queue.count)")
			if playbackInfo.repeatState == .all {
				playbackInfo.currentIndex = 0
			} else {
				pause()
				seek(to: 0)
				return
			}
		} else {
			playbackInfo.currentIndex += 1
		}
		if playbackInfo.queue[playbackInfo.currentIndex].track.streamReady {
//			print("next(): \(playbackInfo.currentIndex) - \(queueCount())")
			avSetItem(from: playbackInfo.queue[playbackInfo.currentIndex].track)
		} else {
			print("Not possible to stream \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
			next()
		}
	}
	
	func shuffle(enabled: Bool) {
		if playbackInfo.queue.isEmpty {
			return
		}
		if enabled {
			playbackInfo.nonShuffledQueue = playbackInfo.queue.map { $0.track }
			playbackInfo.queue = playbackInfo.queue[0...playbackInfo.currentIndex] +
				playbackInfo.queue[playbackInfo.currentIndex+1..<playbackInfo.queue.count].shuffled()
		} else {
			let i = playbackInfo.nonShuffledQueue.firstIndex(where: { $0 == playbackInfo.queue[playbackInfo.currentIndex].track })!
			playbackInfo.queue = playbackInfo.nonShuffledQueue.map { QueueItem(id: 0, track: $0) }
			playbackInfo.assignQueueIndices()
			playbackInfo.currentIndex = i
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
		
		guard let url = track.getAudioUrl(session: session) else {
			failedItems += 1
			if failedItems == playbackInfo.queue.count {
				clearQueue()
			} else {
				next()
			}
			return
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
		if let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) {
			add(tracks: tracks, when)
		}
	}
	
	func add(albums: [Album], _ when: When) {
		albums.forEach { album in
			add(album: album, when)
		}
	}
	
	func add(album: Album, _ when: When) {
		if let tracks = session.getAlbumTracks(albumId: album.id) {
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
	
	func add(tracks: [Track], _ when: When) {
		if when == .now {
			addNow(tracks: tracks)
		} else if when == .next {
			addNext(tracks: tracks)
		} else {
			addLast(tracks: tracks)
		}
	}
	
	private func addNow(tracks: [Track]) {
//		print("addNow(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
//		pause()
		clearQueue()
		if playbackInfo.shuffle {
			playbackInfo.nonShuffledQueue = tracks
			addLast(tracks: tracks.shuffled())
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
		playbackInfo.nonShuffledQueue.insert(contentsOf: tracks, at: playbackInfo.currentIndex)
		let newQueueItems = tracks.map { QueueItem(id: 0, track: $0) }
		if playbackInfo.queue.isEmpty {
			playbackInfo.queue.insert(contentsOf: newQueueItems, at: playbackInfo.currentIndex)
			avSetItem(from: playbackInfo.queue[0].track)
		} else {
			playbackInfo.queue.insert(contentsOf: newQueueItems, at: playbackInfo.currentIndex + 1)
		}
		playbackInfo.assignQueueIndices()
//		print("addNext() finished. Items in Queue: \(playbackInfo.queue.count)")
	}
	
	private func addLast(tracks: [Track]) {
//		print("addLast(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
		let wasEmtpy = playbackInfo.queue.isEmpty
		
		if !playbackInfo.shuffle {
			playbackInfo.nonShuffledQueue.append(contentsOf: tracks)
		}
		
		let newQueueItems = tracks.map { QueueItem(id: 0, track: $0) }
		playbackInfo.queue.append(contentsOf: newQueueItems)
		playbackInfo.assignQueueIndices()
		if wasEmtpy {
			avSetItem(from: playbackInfo.queue[playbackInfo.currentIndex].track)
		}
//		print("addLast() finished. Items in Queue: \(playbackInfo.queue.count)")
	}
	
	func removeTrack(atIndex: Int) {
		if playbackInfo.shuffle {
			let nonShuffledIndex = playbackInfo.nonShuffledQueue.firstIndex(of: playbackInfo.queue[atIndex].track)!
			playbackInfo.nonShuffledQueue.remove(at: nonShuffledIndex)
		} else {
			playbackInfo.nonShuffledQueue.remove(at: atIndex)
		}
		playbackInfo.queue.remove(at: atIndex)
		playbackInfo.assignQueueIndices()
		
		if atIndex == playbackInfo.currentIndex {
			if playbackInfo.queue.count > 0 {
				avSetItem(from: playbackInfo.queue[playbackInfo.currentIndex].track)
			} else {
				avPlayer.replaceCurrentItem(with: nil)
			}
		}
		
		if atIndex < playbackInfo.currentIndex {
			playbackInfo.currentIndex -= 1
		}
	}
	
	func clearQueue() {
		avPlayer.pause()
		playbackInfo.currentIndex = 0
		avPlayer.replaceCurrentItem(with: nil)
		playbackInfo.queue.removeAll()
		playbackInfo.nonShuffledQueue.removeAll()
		
		playbackInfo.playing = false
	}
	
	func queueCount() -> Int {
		return playbackInfo.queue.count
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
		guard !playbackInfo.queue.isEmpty else {
			return ""
		}
		guard let quality = playbackInfo.queue[0].track.audioQuality else {
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
		guard !playbackInfo.queue.isEmpty else {
			return ""
		}
		guard let quality = playbackInfo.queue[0].track.audioQuality else {
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
