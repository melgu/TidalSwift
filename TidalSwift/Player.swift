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
	
	let avPlayer = AVPlayer()
	public let playbackInfo = PlaybackInfo()
	
	public var currentIndex = 0
	public var queue = [Track]()
	
	var timeObserverToken: Any?
	
	init(session: Session) {
		self.session = session
		
		timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: nil) { [weak self] time in
			self?.playbackInfo.fraction = CGFloat(self!.fraction())
		}
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
	
	func pause() {
		avPlayer.pause()
		playbackInfo.playing = false
	}
	
	func previous() {
		if avPlayer.currentTime().seconds >= 3 || currentIndex == 0 {
			avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
			return
		}
		
		currentIndex -= 1
		print("previous(): \(currentIndex) - \(queue.count)")
		avSetItem(from: queue[currentIndex])
		print("previous() done")
	}
	
	func next() {
		if currentIndex >= queue.count - 1 {
			print("next(): \(currentIndex) Last - \(queueCount())")
			pause()
			avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
			return
		}
		currentIndex += 1
		print("next(): \(currentIndex) - \(queueCount())")
		avSetItem(from: queue[currentIndex])
	}
	
	private func avSetItem(from track: Track) {
		print("avSetItem(): \(track.title)")
		let wasPlaying = playbackInfo.playing
		pause()
		
		let url = track.getAudioUrl(session: session)!
		let item = AVPlayerItem(url: url)
		avPlayer.replaceCurrentItem(with: item)
		
		if wasPlaying {
			play()
		}
	}
	
	func addNow(track: Track) {
		addNow(tracks: [track])
	}
	
	func addNow(tracks: [Track]) {
		clearQueue()
		addLast(tracks: tracks)
		print("addNow(): \(queue.count)")
	}
	
	func addNext(track: Track) {
		addNext(tracks: [track])
	}
	
	func addNext(tracks: [Track]) {
		if queue.isEmpty {
			queue.insert(contentsOf: tracks, at: currentIndex)
			avSetItem(from: queue[0])
		} else {
			queue.insert(contentsOf: tracks, at: currentIndex + 1)
		}
		print("addNext(): \(queue.count)")
	}
	
	func addLast(track: Track) {
		addLast(tracks: [track])
	}
	
	func addLast(tracks: [Track]) {
		let wasEmtpy = queue.isEmpty
		
		queue.append(contentsOf: tracks)
		if wasEmtpy {
			avSetItem(from: queue[currentIndex])
		}
		print("addLast(): \(queue.count)")
	}
	
	func clearQueue() {
		avPlayer.pause()
		currentIndex = 0
		avPlayer.replaceCurrentItem(with: nil)
		queue.removeAll()
		
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
	
//	func playerDidFinishPlaying(note: NSNotification) {
//		// Your code here
//	}
}
