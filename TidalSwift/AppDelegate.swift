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
	
	override init() {
		func readDemoLoginCredentials() -> LoginCredentials {
			let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
			var content = ""
			do {
				content = try String(contentsOfFile: fileLocation)
			} catch {
				print("AppDelegate: readDemoLoginCredentials can't open Demo file")
			}

			let lines: [String] = content.components(separatedBy: "\n")
			return LoginCredentials(username: lines[0], password: lines[1])
		}

		let config = Config(quality: .hifi,
							loginCredentials: readDemoLoginCredentials(),
							apiToken: nil)
		session = Session(config: config)
		player = Player(session: session)

		super.init()
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		// My Stuff
		
//		session?.login()
//		session?.saveConfig()
//		session?.saveSession()
		
		session.loadSession()
		print("Login Succesful: \(session.checkLogin())")
//		
//		let demoAlbum = session.getAlbum(albumId: 100006868)!
//		let demoTracks = session.getAlbumTracks(albumId: demoAlbum.id)!
//		
//		player.addNow(tracks: demoTracks)
//		print(player.queueCount())
//		player.play()
		
		print("-----")
		
		// Combine Stuff
		_ = player.playbackInfo.$playing.receive(on: DispatchQueue.main).sink(receiveValue: playLabel(playing:))
		_ = player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffleState(enabled:))
		_ = player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: repeatLabel(repeatState:))
		_ = player.playbackInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: favoriteLabel(currentIndex:))
		_ = player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: muteState(volume:))
		
		// Swift UI Stuff
		window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // Comment out the last if issue of content
			backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")

		window.contentView = NSHostingView(rootView: ContentView(session: session, player: player))
		
		window.makeKeyAndOrderFront(nil)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	// MARK: - Menu Bar
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
		session.favorites?.addTrack(trackId: player.queue[player.playbackInfo.currentIndex].id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var removeFromFavorites: NSMenuItem!
	@IBAction func removeFromFavorites(_ sender: Any) {
		session.favorites?.removeTrack(trackId: player.queue[player.playbackInfo.currentIndex].id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	
	@IBOutlet weak var addToPlaylist: NSMenuItem!
	@IBAction func addToPlaylist(_ sender: Any) {
		print("Add to Playlist")
	}
	@IBOutlet weak var albumAddFavorites: NSMenuItem!
	@IBAction func albumAddFavorites(_ sender: Any) {
		session.favorites?.addAlbum(albumId: player.queue[player.playbackInfo.currentIndex].album.id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var albumRemoveFavorites: NSMenuItem!
	@IBAction func albumRemoveFavorites(_ sender: Any) {
		session.favorites?.removeAlbum(albumId: player.queue[player.playbackInfo.currentIndex].album.id)
		favoriteLabel(currentIndex: player.playbackInfo.currentIndex)
	}
	
	func favoriteLabel(currentIndex: Int) {
		if player.queue.isEmpty {
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
		
		if player.queue[currentIndex].isInFavorites(session: session)! {
			addToFavorites.isHidden = true
			removeFromFavorites.isHidden = false
		} else {
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
		}
		
		if player.queue[currentIndex].album.isInFavorites(session: session)! {
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
		print("Logout")
	}
	
	// MARK: - View
	
	@IBAction func lyrics(_ sender: Any) {
		if !self.player.queue.isEmpty {
			Lyrics.showLyrics(for: self.player.queue[self.player.playbackInfo.currentIndex])
		}
	}
	@IBAction func queue(_ sender: Any) {
		print("Queue")
	}
	
}

