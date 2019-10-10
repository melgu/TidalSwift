//
//  Player.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import AVFoundation
import TidalSwiftLib

class Player {
	let session: Session
	var autoplayAfterAddNow: Bool
	
	let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	
	public var queue = [Track]()
	private var nonShuffledQueue = [Track]()
	
	private var timeObserverToken: Any?
	
	private var previousValue: Float = 1.0
	
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
		if (!queue.isEmpty) {
			avPlayer.play()
			playbackInfo.playing = true
		}
	}
	
	func play(atIndex: Int) {
		if queue.count > atIndex {
			playbackInfo.currentIndex = atIndex
			avSetItem(from: queue[playbackInfo.currentIndex])
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
			if playbackInfo.currentIndex == 0 && !queue[playbackInfo.currentIndex].streamReady {
				print("Not possible to stream \(queue[playbackInfo.currentIndex].title)")
				pause()
				next()
			}
			return
		}
		
		playbackInfo.currentIndex -= 1
		if queue[playbackInfo.currentIndex].streamReady {
			print("previous(): \(playbackInfo.currentIndex) - \(queue.count)")
			avSetItem(from: queue[playbackInfo.currentIndex])
			print("previous() done")
		} else {
			print("Not possible to stream \(queue[playbackInfo.currentIndex].title)")
			previous()
		}
	}
	
	func next() {
		if playbackInfo.repeatState == .single {
			seek(to: 0)
			play()
			return
		}
		
		if playbackInfo.currentIndex >= queue.count - 1 {
			print("next(): \(playbackInfo.currentIndex) Last - \(queueCount())")
			if playbackInfo.repeatState == .all {
				playbackInfo.currentIndex = 0
			} else {
				pause()
				seek(to: 0)
			}
		} else {
			playbackInfo.currentIndex += 1
		}
		if queue[playbackInfo.currentIndex].streamReady {
			print("next(): \(playbackInfo.currentIndex) - \(queueCount())")
			avSetItem(from: queue[playbackInfo.currentIndex])
		} else {
			print("Not possible to stream \(queue[playbackInfo.currentIndex].title)")
			next()
		}
	}
	
	func shuffle(enabled: Bool) {
		if queue.isEmpty {
			return
		}
		if enabled {
			nonShuffledQueue = queue
			queue = queue[0...playbackInfo.currentIndex] + queue[playbackInfo.currentIndex+1..<queue.count].shuffled()
		} else {
			let i = nonShuffledQueue.firstIndex(where: { $0 == queue[playbackInfo.currentIndex] })!
			queue = nonShuffledQueue
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
		print("avSetItem(): \(track.title)")
		let wasPlaying = playbackInfo.playing
		pause()
		
		guard let url = track.getAudioUrl(session: session) else {
			next()
			return
		}
		let item = AVPlayerItem(url: url)
		NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		avPlayer.replaceCurrentItem(with: item)
		
		if wasPlaying {
			play()
		}
	}
	
	@objc func playerDidFinishPlaying(sender: Notification) {
		print("Song finished playing")
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
//		let ts = cleanTracks(tracks)
		if when == .now {
			addNow(tracks: tracks)
		} else if when == .next {
			addNext(tracks: tracks)
		} else {
			addLast(tracks: tracks)
		}
	}
	
	private func addNow(tracks: [Track]) {
		if tracks.isEmpty {
			return
		}
		clearQueue()
		if playbackInfo.shuffle {
			nonShuffledQueue = tracks
			addLast(tracks: tracks.shuffled())
		} else {
			addLast(tracks: tracks)
		}
		print("addNow(): \(queue.count)")
		play()
	}
	
	private func addNext(tracks: [Track]) {
		if tracks.isEmpty {
			return
		}
		nonShuffledQueue.insert(contentsOf: tracks, at: playbackInfo.currentIndex)
		if queue.isEmpty {
			queue.insert(contentsOf: tracks, at: playbackInfo.currentIndex)
			avSetItem(from: queue[0])
		} else {
			queue.insert(contentsOf: tracks, at: playbackInfo.currentIndex + 1)
		}
		print("addNext(): \(queue.count)")
	}
	
	private func addLast(tracks: [Track]) {
		if tracks.isEmpty {
			return
		}
		let wasEmtpy = queue.isEmpty
		
		if !playbackInfo.shuffle {
			nonShuffledQueue.append(contentsOf: tracks)
		}
		
		queue.append(contentsOf: tracks)
		if wasEmtpy {
			avSetItem(from: queue[playbackInfo.currentIndex])
		}
		print("addLast(): \(queue.count)")
	}
	
//	private func cleanTracks(_ tracks: [Track]) -> [Track] {
//		var ts = tracks
//		ts.removeAll(where: { !$0.streamReady })
//		return ts
//	}
	
	func clearQueue() {
		avPlayer.pause()
		playbackInfo.currentIndex = 0
		avPlayer.replaceCurrentItem(with: nil)
		queue.removeAll()
		nonShuffledQueue.removeAll()
		
		playbackInfo.playing = false
	}
	
	func queueCount() -> Int {
		return queue.count
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
		guard !queue.isEmpty else {
			return ""
		}
		guard let quality = queue[0].audioQuality else {
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
		guard !queue.isEmpty else {
			return ""
		}
		guard let quality = queue[0].audioQuality else {
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
