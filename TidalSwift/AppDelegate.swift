//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa
import SwiftUI
import TidalSwiftLib

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var window: NSWindow!
	
	var session: Session
	var player: Player
	var viewState = ViewState()
	
	// Login
	let loginInfo = LoginInfo()
	
	override init() {
		session = Session(config: nil)
		player = Player(session: session)
		
		super.init()
	}
	
	func login(username: String, password: String, quality: AudioQuality) {
		let credentials = LoginCredentials(username: username, password: password)
		let config = Config(quality: quality, loginCredentials: credentials)
		session = Session(config: config)
		
		let loginSuccessful = session.login()
		if loginSuccessful {
			loginInfo.wrongLogin = false
			loginInfo.showLoginView = false
			session.saveConfig()
			session.saveSession()
			player = Player(session: session)
		} else {
			loginInfo.wrongLogin = true
		}
	}
	
	func logout() {
		print("Logout")
		loginInfo.showLoginView = true
		session.deletePersistentInformation()
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		// My Stuff
		
		session.loadSession()
		let loggedIn = session.checkLogin()
		print("Login Succesful: \(loggedIn)")
		
		loginInfo.showLoginView = !loggedIn
		
		// Retrieve Playback State
		if let data = UserDefaults.standard.data(forKey: "PlaybackInfo") {
			if let tempPI = try? JSONDecoder().decode(CodablePlaybackInfo.self, from: data) {
				player.playbackInfo.nonShuffledQueue = tempPI.nonShuffledQueue
				player.playbackInfo.queue = tempPI.queue
				player.playbackInfo.volume = tempPI.volume
				player.playbackInfo.shuffle = tempPI.shuffle
				player.playbackInfo.repeatState = tempPI.repeatState
				
				player.play(atIndex: tempPI.currentIndex)
				player.pause()
				// TODO: Seeking at this point doesn't work. Why?
//				player.seek(to: Double(tempPI.fraction))
//				print("Wanted: \(Double(tempPI.fraction)), Actual: \(player.playbackInfo.fraction)")
			}
		}
		
		print("-----")
		
		// Space for Play/Pause
		// Currently deactivated, because no way to know, if currently writing text in a TextField
//		NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
//			if event.characters == " " {
//				self.player.togglePlay()
//			}
//			return event
//		}
		
		// Combine Stuff
		_ = player.playbackInfo.$playing.receive(on: DispatchQueue.main).sink(receiveValue: playLabel(playing:))
		_ = player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffleState(enabled:))
		_ = player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: repeatLabel(repeatState:))
		_ = player.playbackInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: favoriteLabel(currentIndex:))
		_ = player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: muteState(volume:))
		_ = viewState.$viewType.receive(on: DispatchQueue.main).sink(receiveValue: { print("View: \($0 ?? "nil")") })
		
		// Swift UI Stuff
		window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // Comment out the last if issue of content
			backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")
		
		window.contentView = NSHostingView(rootView:
			ContentView(viewState: viewState, session: session, player: player)
				.environmentObject(loginInfo)
		)
		
		window.makeKeyAndOrderFront(nil)
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	// MARK: - Menu Bar
	// MARK: - Quit
	
	@IBAction func Quit(_ sender: Any) {
		print("Exiting...")
		loginInfo.showLoginView = false
		
		// Save Playback State
		let codablePI = CodablePlaybackInfo(nonShuffledQueue: player.playbackInfo.nonShuffledQueue,
											queue: player.playbackInfo.queue,
											currentIndex: player.playbackInfo.currentIndex,
											fraction: player.playbackInfo.fraction,
											playing: player.playbackInfo.playing,
											volume: player.playbackInfo.volume,
											shuffle: player.playbackInfo.shuffle,
											repeatState: player.playbackInfo.repeatState)
		let data = try? JSONEncoder().encode(codablePI)
		UserDefaults.standard.set(data, forKey: "PlaybackInfo")
		UserDefaults.standard.synchronize()
		
		NSApp.terminate(nil)
	}
	
	// MARK: File
	
	@IBAction func downloadTrack(_ sender: Any) {
		print("Menu: downloadTrack")
	}
	@IBAction func downloadAlbum(_ sender: Any) {
		print("Menu: downloadAlbum")
	}
	@IBAction func downloadPlaylist(_ sender: Any) {
		print("Menu: downloadPlaylist")
	}
	
	@IBOutlet weak var albumToggleOffline: NSMenuItem!
	@IBAction func albumToggleOffline(_ sender: Any) {
		albumToggleOffline.state = albumToggleOffline.state == .on ? .off : .on
	}
	@IBOutlet weak var trackToggleOffline: NSMenuItem!
	@IBAction func trackToggleOffline(_ sender: Any) {
		trackToggleOffline.state = trackToggleOffline.state == .on ? .off : .on
	}
	@IBOutlet weak var playlistToggleOffline: NSMenuItem!
	@IBAction func playlistToggleOffline(_ sender: Any) {
		playlistToggleOffline.state = playlistToggleOffline.state == .on ? .off : .on
	}
	
	// MARK: - Edit
	
	@IBAction func find(_ sender: Any) {
		print("Find")
	}
	
	// MARK: - Track
	
	@IBOutlet weak var goToAlbum: NSMenuItem!
	@IBAction func goToAlbum(_ sender: Any) {
		print("Go to Album")
	}
	@IBOutlet weak var goToArtist: NSMenuItem!
	@IBAction func goToArtist(_ sender: Any) {
		print("Go to Artist")
	}
	
	@IBOutlet weak var addToFavorites: NSMenuItem!
	@IBAction func addToFavorites(_ sender: Any) {
		session.favorites?.addTrack(trackId: player.playbackInfo.queue[player.playbackInfo.currentIndex].id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var removeFromFavorites: NSMenuItem!
	@IBAction func removeFromFavorites(_ sender: Any) {
		session.favorites?.removeTrack(trackId: player.playbackInfo.queue[player.playbackInfo.currentIndex].id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	
	@IBOutlet weak var addToPlaylist: NSMenuItem!
	@IBAction func addToPlaylist(_ sender: Any) {
		print("Add to Playlist")
	}
	@IBOutlet weak var albumAddFavorites: NSMenuItem!
	@IBAction func albumAddFavorites(_ sender: Any) {
		session.favorites?.addAlbum(albumId: player.playbackInfo.queue[player.playbackInfo.currentIndex].album.id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var albumRemoveFavorites: NSMenuItem!
	@IBAction func albumRemoveFavorites(_ sender: Any) {
		session.favorites?.removeAlbum(albumId: player.playbackInfo.queue[player.playbackInfo.currentIndex].album.id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	
	func favoriteLabel(currentIndex: Int) {
		if player.playbackInfo.queue.isEmpty {
			goToAlbum.isEnabled = false
			goToArtist.isEnabled = false
			
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
			addToFavorites.isEnabled = false
			
			addToPlaylist.isEnabled = false
			
			albumAddFavorites.isHidden = false
			albumRemoveFavorites.isHidden = true
			albumAddFavorites.isEnabled = false
			return
		} else {
			goToAlbum.isEnabled = true
			goToArtist.isEnabled = true
			addToFavorites.isEnabled = true
			addToPlaylist.isEnabled = true
			albumAddFavorites.isEnabled = true
		}
		
		if player.playbackInfo.queue[currentIndex].isInFavorites(session: session)! {
			addToFavorites.isHidden = true
			removeFromFavorites.isHidden = false
		} else {
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
		}
		
		if player.playbackInfo.queue[currentIndex].album.isInFavorites(session: session)! {
			albumAddFavorites.isHidden = true
			albumRemoveFavorites.isHidden = false
		} else {
			albumAddFavorites.isHidden = false
			albumRemoveFavorites.isHidden = true
			albumAddFavorites.isEnabled = true
		}
	}
	
	// MARK: - Control
	
	@IBOutlet weak var play: NSMenuItem!
	@IBAction func play(_ sender: Any) {
		player.togglePlay()
	}
	func playLabel(playing: Bool) {
		if playing {
			play.title = "Pause"
		} else {
			play.title = "Play"
		}
	}
	@IBAction func stop(_ sender: Any) {
		player.stop()
	}
	@IBAction func next(_ sender: Any) {
		player.next()
	}
	@IBAction func previous(_ sender: Any) {
		player.previous()
	}
	
	@IBAction func increaseVolume(_ sender: Any) {
		player.increaseVolume()
	}
	@IBAction func decreaseVolume(_ sender: Any) {
		player.decreaseVolume()
	}
	@IBOutlet weak var mute: NSMenuItem!
	@IBAction func mute(_ sender: Any) {
		player.toggleMute()
	}
	func muteState(volume: Float) {
		mute.state = volume == 0 ? .on : .off
	}
	
	@IBOutlet weak var shuffle: NSMenuItem!
	@IBAction func shuffle(_ sender: Any) {
		player.playbackInfo.shuffle.toggle()
	}
	func shuffleState(enabled: Bool) {
		shuffle.state = enabled ? .on : .off
	}
	
	@IBOutlet weak var repeatOff: NSMenuItem!
	@IBAction func repeatOff(_ sender: Any) {
		player.playbackInfo.repeatState = .off
	}
	@IBOutlet weak var repeatAll: NSMenuItem!
	@IBAction func repeatAll(_ sender: Any) {
		player.playbackInfo.repeatState = .all
	}
	@IBOutlet weak var repeatSingle: NSMenuItem!
	@IBAction func repeatSingle(_ sender: Any) {
		player.playbackInfo.repeatState = .single
	}
	func repeatLabel(repeatState: RepeatState) {
		switch repeatState {
		case .off:
			repeatOff.state = .on
			repeatAll.state = .off
			repeatSingle.state = .off
		case .all:
			repeatOff.state = .off
			repeatAll.state = .on
			repeatSingle.state = .off
		case .single:
			repeatOff.state = .off
			repeatAll.state = .off
			repeatSingle.state = .on
		}
	}
	
	@IBAction func clearQueue(_ sender: Any) {
		player.clearQueue()
	}
	
	// MARK: - Account
	
	@IBAction func accountInfo(_ sender: Any) {
		print("accountInfo")
	}
	@IBAction func logout(_ sender: Any) {
		logout()
	}
	
	// MARK: - View
	
	@IBAction func lyrics(_ sender: Any) {
		if !self.player.playbackInfo.queue.isEmpty {
			Lyrics.showLyricsWindow(for: self.player.playbackInfo.queue[self.player.playbackInfo.currentIndex])
		}
	}
	@IBAction func queue(_ sender: Any) {
		player.showQueueWindow()
	}
}

