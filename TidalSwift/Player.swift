//
//  Player.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import AVFoundation
import TidalSwiftLib

@Observable
class Player {
	private let session: Session
	private var autoplayAfterAddNow: Bool
	
	private let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	public let queueInfo = QueueInfo()
	@ObservationIgnored private let nowPlaying: NowPlaying
	
	@ObservationIgnored private var timeObserverToken: Any?
	@ObservationIgnored private var lyricsTimeObserverToken: Any?
	@ObservationIgnored private var isFollowingLyrics = false
	@ObservationIgnored private var lyricsLineTimes: [Double] = []
	
	@ObservationIgnored private var previousValue: Float = 1.0
	@ObservationIgnored private var failedItems = 0
	// Incremented on every item change, so outdated async loads can be discarded
	@ObservationIgnored private var itemLoadID = 0
	
	private var currentAudioQuality: AudioQuality
	private var currentIsDolbyAtmos = false
	private(set) var nextAudioQuality: AudioQuality
	private(set) var preferDolbyAtmos: Bool
	
	init(session: Session, audioQuality: AudioQuality, preferDolbyAtmos: Bool = false, autoplayAfterAddNow: Bool = true) {
		self.session = session
		self.currentAudioQuality = audioQuality
		self.nextAudioQuality = audioQuality
		self.preferDolbyAtmos = preferDolbyAtmos
		self.autoplayAfterAddNow = autoplayAfterAddNow
		self.nowPlaying = NowPlaying(session: session)
		
		timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] _ in
			if let self {
				Task { @MainActor in
					self.playbackInfo.fraction = CGFloat(self.fraction())
					self.playbackInfo.playbackTimeInfo = self.playbackTimeInfo()
					// Boundary observers miss seeks, but this one also fires on every time jump
					self.updateActiveLyricsLine()
				}
			}
		}
		
		playbackInfo.onVolumeChange = { [weak self] in self?.setVolume(to: $0) }
		playbackInfo.onShuffleChange = { [weak self] in self?.shuffle(enabled: $0) }
		
		nowPlaying.register(NowPlaying.Commands(
			play: { [weak self] in self?.play() },
			pause: { [weak self] in self?.pause() },
			togglePlay: { [weak self] in self?.togglePlay() },
			next: { [weak self] in self?.next() },
			previous: { [weak self] in self?.previous() },
			seek: { [weak self] in self?.seek(toSeconds: $0) }
		))
	}
	
	@MainActor
	deinit {
		if let token = timeObserverToken {
			avPlayer.removeTimeObserver(token)
			timeObserverToken = nil
		}
		if let token = lyricsTimeObserverToken {
			avPlayer.removeTimeObserver(token)
			lyricsTimeObserverToken = nil
		}
	}
	
	// Only runs while the lyrics are visible
	func setLyricsFollowing(enabled: Bool) {
		isFollowingLyrics = enabled
		updateLyricsTimeObserver()
	}
	
	// Start times of the current track's synced lyrics lines, empty if there are none
	func setLyricsLineTimes(_ times: [Double]) {
		lyricsLineTimes = times
		updateLyricsTimeObserver()
	}
	
	// A boundary observer fires exactly when a line starts, instead of polling the time
	private func updateLyricsTimeObserver() {
		if let token = lyricsTimeObserverToken {
			avPlayer.removeTimeObserver(token)
			lyricsTimeObserverToken = nil
		}
		guard isFollowingLyrics, !lyricsLineTimes.isEmpty else {
			playbackInfo.activeLyricsLine = nil
			return
		}
		let times = lyricsLineTimes.map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 600)) }
		lyricsTimeObserverToken = avPlayer.addBoundaryTimeObserver(forTimes: times, queue: nil) { [weak self] in
			Task { @MainActor in
				self?.updateActiveLyricsLine()
			}
		}
		updateActiveLyricsLine()
	}
	
	private func updateActiveLyricsLine() {
		guard isFollowingLyrics else {
			return
		}
		// The boundary observer can fire marginally before the line's start time
		let seconds = avPlayer.currentTime().seconds + 0.05
		let activeLine = lyricsLineTimes.lastIndex { $0 <= seconds }
		if activeLine != playbackInfo.activeLyricsLine {
			playbackInfo.activeLyricsLine = activeLine
		}
	}
	
	func setAudioQuality(to audioQuality: AudioQuality) {
		nextAudioQuality = audioQuality
	}
	
	func setPreferDolbyAtmos(to preferDolbyAtmos: Bool) {
		self.preferDolbyAtmos = preferDolbyAtmos
	}
	
	func play() {
		if !queueInfo.queue.isEmpty {
//			print("Play: \(playbackInfo.queue[playbackInfo.currentIndex].track.title)")
			avPlayer.play()
			playbackInfo.playing = true
			nowPlaying.update(playing: true, elapsed: avPlayer.currentTime().seconds)
			queueInfo.addToHistory(track: queueInfo.queue[queueInfo.currentIndex])
		}
	}
	
	func play(atIndex: Int) {
		if queueInfo.queue.count > atIndex {
			queueInfo.currentIndex = atIndex
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex])
			play()
		}
	}
	
	func pause() {
		avPlayer.pause()
		playbackInfo.playing = false
		nowPlaying.update(playing: false, elapsed: avPlayer.currentTime().seconds)
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
			seek(toSeconds: 0)
			if queueInfo.currentIndex == 0 && !queueInfo.queue[queueInfo.currentIndex].isPlayable {
				print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].title)")
				pause()
				next()
			}
			return
		}
		
		queueInfo.currentIndex -= 1
		if queueInfo.queue[queueInfo.currentIndex].isPlayable {
//			print("previous(): \(playbackInfo.currentIndex) - \(playbackInfo.queue.count)")
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex])
//			print("previous() done")
		} else {
			print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].title)")
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
		if queueInfo.queue[queueInfo.currentIndex].isPlayable {
//			print("next(): \(playbackInfo.currentIndex) - \(queueCount())")
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex])
		} else {
			print("Not possible to stream \(queueInfo.queue[queueInfo.currentIndex].title)")
			next()
		}
		
		if playbackInfo.pauseAfter {
			pause()
		}
	}
	
	private func shuffle(enabled: Bool) {
		if queueInfo.queue.isEmpty {
			return
		}
		if enabled {
			queueInfo.nonShuffledQueue = queueInfo.queue
			queueInfo.queue = queueInfo.queue[0...queueInfo.currentIndex] +
				queueInfo.queue[queueInfo.currentIndex + 1..<queueInfo.queue.count].shuffled()
		} else {
			if let i = queueInfo.nonShuffledQueue.firstIndex(where: { $0 == queueInfo.queue[queueInfo.currentIndex] }) {
				queueInfo.queue = queueInfo.nonShuffledQueue
				queueInfo.currentIndex = i
			}
		}
	}
	
	func seek(to percentage: Double) {
		guard let currentItem = avPlayer.currentItem else {
			return
		}
		seek(toSeconds: percentage * currentItem.duration.seconds)
	}
	
	func seek(toSeconds seconds: Double) {
		avPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
		nowPlaying.update(playing: playbackInfo.playing, elapsed: seconds)
	}
	
	private func avSetItem(from track: Track) {
		itemLoadID += 1
		let loadID = itemLoadID
		Task {
			await avSetItemAsync(from: track, loadID: loadID)
		}
	}
	
	private func avSetItemAsync(from track: Track, loadID: Int) async {
//		print("avSetItem(): \(track.title)")
		guard loadID == itemLoadID else {
			return
		}
		avPlayer.pause()
		
		func skip() {
			failedItems += 1
			if failedItems == queueInfo.queue.count {
				clearQueue()
			} else {
				next()
			}
		}
		
		if !track.isPlayable {
			skip()
			return
		}
		
		let url: URL
		let isDolbyAtmos: Bool
		if let offlineStream = await session.helpers.offline.stream(for: track) {
			url = offlineStream.url
			isDolbyAtmos = offlineStream.isDolbyAtmos
			print("Play \(track.title) from offline URL\(offlineStream.isDolbyAtmos ? " (Dolby Atmos)" : ""): \(offlineStream.url)")
		} else {
			if let stream = await track.audioStream(session: session, audioQuality: nextAudioQuality, preferDolbyAtmos: preferDolbyAtmos) {
				url = stream.url
				isDolbyAtmos = stream.isDolbyAtmos
				print("Play \(track.title) from online URL\(stream.isDolbyAtmos ? " (Dolby Atmos)" : ""): \(stream.url)")
			} else {
				guard loadID == itemLoadID else {
					return
				}
				print("No URL so skipping \(track.title)")
				skip()
				return
			}
		}
		// Another item was requested while this one was loading
		guard loadID == itemLoadID else {
			return
		}
		failedItems = 0
		
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
		
		let item = AVPlayerItem(url: url)
		NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		avPlayer.replaceCurrentItem(with: item)
		
		currentAudioQuality = nextAudioQuality
		currentIsDolbyAtmos = isDolbyAtmos
		
		nowPlaying.update(track: track)
		if playbackInfo.playing {
			play()
		} else {
			nowPlaying.update(playing: false, elapsed: 0)
		}
	}
	
	@objc private func playerDidFinishPlaying(sender: Notification) {
//		print("Song finished playing")
		next()
	}
	
	private func add(playlists: [Playlist], _ when: When) {
		playlists.forEach { playlist in
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
	
	private func add(albums: [Album], _ when: When) {
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
	
	func add(track: Track, _ when: When) {
		add(tracks: [track], when)
	}
	
	enum When {
		case now
		case next
		case last
	}
	
	func add(tracks: [Track], _ when: When, playAt index: Int = 0) {
		let unavailableCount = tracks[0..<index].filter { !$0.isPlayable }.count
		let newIndex = index - unavailableCount
		print("New Index: \(newIndex), index: \(index), \(unavailableCount)")
		
		let tracks = tracks.filter(\.isPlayable)
		if when == .now {
			addNow(tracks: tracks, playAt: newIndex)
			play(atIndex: newIndex)
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
		
		let wasPlaying = playbackInfo.playing
		clearQueue()
		if playbackInfo.shuffle {
			addLast(tracks: Array(tracks[0...index]))
			if index + 1 < tracks.count {
				addLast(tracks: tracks[index + 1..<tracks.count].shuffled())
			}
			queueInfo.nonShuffledQueue = tracks
		} else {
			addLast(tracks: tracks)
		}
		if wasPlaying {
			play()
		}
//		print("addNow() finished. Items in Queue: \(playbackInfo.queue.count)")
	}
	
	private func addNext(tracks: [Track]) {
//		print("addNext(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
		// Insert after the current track in the non-shuffled order too, as currentIndex refers to the shuffled queue
		let nonShuffledIndex: Int
		if let current = queueInfo.currentItem,
		   let i = queueInfo.nonShuffledQueue.firstIndex(of: current) {
			nonShuffledIndex = i + 1
		} else {
			nonShuffledIndex = queueInfo.nonShuffledQueue.count
		}
		queueInfo.nonShuffledQueue.insert(contentsOf: tracks, at: nonShuffledIndex)
		let newQueueItems = tracks
		if queueInfo.queue.isEmpty {
			queueInfo.queue.insert(contentsOf: newQueueItems, at: queueInfo.currentIndex)
			avSetItem(from: queueInfo.queue[0])
		} else {
			queueInfo.queue.insert(contentsOf: newQueueItems, at: queueInfo.currentIndex + 1)
		}
//		print("addNext() finished. Items in Queue: \(queueInfo.queue.count)")
	}
	
	private func addLast(tracks: [Track]) {
//		print("addLast(): \(tracks.count)")
		if tracks.isEmpty {
			return
		}
		let wasEmtpy = queueInfo.queue.isEmpty
		
		queueInfo.nonShuffledQueue.append(contentsOf: tracks)
		
		let newQueueItems = tracks
		queueInfo.queue.append(contentsOf: newQueueItems)
		if wasEmtpy {
			avSetItem(from: queueInfo.queue[queueInfo.currentIndex])
		}
//		print("addLast() finished. Items in Queue: \(queueInfo.queue.count)")
	}
	
	func removeTrack(atIndex: Int) {
		if playbackInfo.shuffle {
			guard let nonShuffledIndex = queueInfo.nonShuffledQueue.firstIndex(of: queueInfo.queue[atIndex]) else {
				print("ERROR - Player.removeTrack(): queueInfo.nonShuffledQueue.firstIndex is nil")
				return
			}
			queueInfo.nonShuffledQueue.remove(at: nonShuffledIndex)
		} else {
			queueInfo.nonShuffledQueue.remove(at: atIndex)
		}
		queueInfo.queue.remove(at: atIndex)
		let removedCurrent = atIndex == queueInfo.currentIndex
		
		// Removed the current track while it was last in the queue
		if queueInfo.currentIndex >= queueInfo.queue.count {
			queueInfo.currentIndex = max(queueInfo.queue.count - 1, 0)
		}
		
		if removedCurrent {
			if !queueInfo.queue.isEmpty {
				avSetItem(from: queueInfo.queue[queueInfo.currentIndex])
			} else {
				avPlayer.replaceCurrentItem(with: nil)
				nowPlaying.clear()
			}
		}
		
		if atIndex < queueInfo.currentIndex {
			queueInfo.currentIndex -= 1
		}
	}
	
	func clearQueue(leavingCurrent: Bool = false) {
		if leavingCurrent {
			guard let current = queueInfo.currentItem else {
				clearQueue()
				return
			}
			queueInfo.queue = [current]
			queueInfo.currentIndex = 0
			queueInfo.nonShuffledQueue = queueInfo.queue
		} else {
			itemLoadID += 1
			avPlayer.pause()
			playbackInfo.playing = false
			queueInfo.currentIndex = 0
			avPlayer.replaceCurrentItem(with: nil)
			nowPlaying.clear()
			queueInfo.queue.removeAll()
			queueInfo.nonShuffledQueue.removeAll()
		}
	}
	
	private func queueCount() -> Int {
		queueInfo.queue.count
	}
	
	private func fraction() -> Double {
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
	
	private func playbackTimeInfo() -> String {
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
	
	private func setVolume(to volume: Float) {
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
		if currentIsDolbyAtmos {
			return "ATMOS"
		}
		guard let quality = queueInfo.queue[queueInfo.currentIndex].audioQuality else {
			return ""
		}
		
		var chosenQuality = currentAudioQuality
//		print("\(chosenQuality) \(quality)")
		
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
		let track = queueInfo.queue[queueInfo.currentIndex]
		// Tidal reports Atmos-only tracks as LOW, which says nothing about the Atmos stream
		guard track.hasStereo else {
			return track.hasDolbyAtmos ? "ATMOS" : ""
		}
		guard let quality = track.audioQuality else {
			return ""
		}
		
		let stereoQuality = track.hasHiRes ? "MAX" : qualityToString(quality: quality)
		return stereoQuality + (track.hasDolbyAtmos ? " · ATMOS" : "")
	}
	
	private func qualityToString(quality: AudioQuality) -> String {
		switch quality {
		case .low:
			return "LOW 96"
		case .medium:
			return "LOW 320"
		case .high:
			return "HIGH"
		}
	}
}
