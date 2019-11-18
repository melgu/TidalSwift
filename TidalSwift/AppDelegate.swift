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
	
	var sc: SessionContainer
	var viewState = ViewState()
	var playlistEditingValues = PlaylistEditingValues()
	
	// Login
	let loginInfo = LoginInfo()
	
	// Secondary Windows
	var lyricsViewController: NSWindowController
	var queueViewController: NSWindowController
	var viewHistoryViewController: NSWindowController
	var playbackHistoryViewController: NSWindowController
	
	override init() {
		let session = Session(config: nil)
		let player = Player(session: session)
		sc = SessionContainer(session: session, player: player)
		
		// Init Secondary Windows (cannot use method func because self is not initialized yet
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(sc.player.playbackInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: sc.session, player: sc.player)
				.environmentObject(sc)
				.environmentObject(sc.player.playbackInfo)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(rootView:
			PlaybackHistoryView()
				.environmentObject(sc)
				.environmentObject(sc.player.playbackInfo)
		)
		playbackHistoryViewController.window?.title = "Playback History"
		
		super.init()
	}
	
	func initSecondaryWindows() {
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(sc.player.playbackInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: sc.session, player: sc.player)
				.environmentObject(sc.player.playbackInfo)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(rootView:
			PlaybackHistoryView()
				.environmentObject(sc)
				.environmentObject(sc.player.playbackInfo)
		)
		playbackHistoryViewController.window?.title = "Playback History"
	}
	
	func closeAllSecondaryWindows() {
		lyricsViewController.close()
		queueViewController.close()
		viewHistoryViewController.close()
		playbackHistoryViewController.close()
	}
	
	func login(username: String, password: String, quality: AudioQuality) {
		let credentials = LoginCredentials(username: username, password: password)
		let config = Config(quality: quality, loginCredentials: credentials)
		sc.session = Session(config: config)
		
		let loginSuccessful = sc.session.login()
		if loginSuccessful {
			loginInfo.wrongLogin = false
			loginInfo.showModal = false
			sc.session.saveConfig()
			sc.session.saveSession()
			sc.player = Player(session: sc.session)
			initSecondaryWindows()
		} else {
			loginInfo.wrongLogin = true
		}
	}
	
	func logout() {
		print("Logout")
		closeModals()
		closeAllSecondaryWindows()
		sc.player.clearQueue()
		sc.session.deletePersistentInformation()
		viewState.clear()
		loginInfo.showModal = true
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		sc.session.loadSession()
		let loggedIn = sc.session.checkLogin()
		print("Login Succesful: \(loggedIn)")
		
		loginInfo.showModal = !loggedIn
		
		if loggedIn {
			// Retrieve Playback State
			if let data = UserDefaults.standard.data(forKey: "PlaybackInfo") {
				if let tempPI = try? JSONDecoder().decode(CodablePlaybackInfo.self, from: data) {
					sc.player.playbackInfo.nonShuffledQueue = tempPI.nonShuffledQueue
					sc.player.playbackInfo.queue = tempPI.queue
					sc.player.playbackInfo.volume = tempPI.volume
					sc.player.playbackInfo.shuffle = tempPI.shuffle
					sc.player.playbackInfo.repeatState = tempPI.repeatState
					sc.player.playbackInfo.history = tempPI.history
					sc.player.playbackInfo.maxHistoryItems = tempPI.maxHistoryItems
					
					sc.player.play(atIndex: tempPI.currentIndex)
					sc.player.pause()
					// TODO: Seeking at this point doesn't work. Why?
//					player.seek(to: Double(tempPI.fraction))
//					print("Wanted: \(Double(tempPI.fraction)), Actual: \(player.playbackInfo.fraction)")
				}
			}
			
			// Retrieve View Stack
			if let data = UserDefaults.standard.data(forKey: "ViewStateStack") {
				if let tempStack = try? JSONDecoder().decode([TidalSwiftView].self, from: data) {
					viewState.stack = tempStack
					if viewState.stack.count > 0 {
						viewState.viewType = tempStack.last!.viewType
						viewState.searchTerm = tempStack.last!.searchTerm
						viewState.fixedSearchTerm = tempStack.last!.searchTerm
						viewState.artist = tempStack.last!.artist
						viewState.album = tempStack.last!.album
						viewState.playlist = tempStack.last!.playlist
						viewState.mix = tempStack.last!.mix
					}
				}
			}
			
			if let data = UserDefaults.standard.data(forKey: "ViewStateHistory") {
				if let tempHistory = try? JSONDecoder().decode([TidalSwiftView].self, from: data) {
					viewState.history = tempHistory
				}
			}
		}
		
		// Space for Play/Pause
		// Currently deactivated, because no way to know, if currently writing text in a TextField
//		NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
//			if event.characters == " " {
//				self.player.togglePlay()
//			}
//			return event
//		}
		
		// Combine Stuff
		_ = sc.player.playbackInfo.$playing.receive(on: DispatchQueue.main).sink(receiveValue: playLabel(playing:))
		_ = sc.player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffleState(enabled:))
		_ = sc.player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: repeatLabel(repeatState:))
		_ = sc.player.playbackInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: favoriteLabel(currentIndex:))
		_ = sc.player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: muteState(volume:))
		_ = viewState.$viewType.receive(on: DispatchQueue.main).sink(receiveValue: { print("View: \($0?.rawValue ?? "nil")") })
		
		// Swift UI Stuff
		window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // Comment out the last if issue of content
			backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")
		
		window.contentView = NSHostingView(rootView:
			ContentView()
				.environmentObject(sc)
				.environmentObject(viewState)
				.environmentObject(loginInfo)
				.environmentObject(playlistEditingValues)
		)
		
		window.makeKeyAndOrderFront(nil)
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func closeModals() {
		loginInfo.showModal = false
		playlistEditingValues.showAddTracksModal = false
		playlistEditingValues.showRemoveTracksModal = false
		playlistEditingValues.showDeleteModal = false
		playlistEditingValues.showEditModal = false
	}
	
	// MARK: - Menu Bar
	// MARK: - Quit
	
	@IBAction func Quit(_ sender: Any) {
		print("Exiting...")
		closeModals()
		
		// Save Playback State
		let codablePI = CodablePlaybackInfo(nonShuffledQueue: sc.player.playbackInfo.nonShuffledQueue,
											queue: sc.player.playbackInfo.queue,
											currentIndex: sc.player.playbackInfo.currentIndex,
											fraction: sc.player.playbackInfo.fraction,
											playing: sc.player.playbackInfo.playing,
											volume: sc.player.playbackInfo.volume,
											shuffle: sc.player.playbackInfo.shuffle,
											repeatState: sc.player.playbackInfo.repeatState,
											history: sc.player.playbackInfo.history,
											maxHistoryItems: sc.player.playbackInfo.maxHistoryItems)
		let playbackInfoData = try? JSONEncoder().encode(codablePI)
		UserDefaults.standard.set(playbackInfoData, forKey: "PlaybackInfo")
		
		// Save View Stack & History
		let viewStackData = try? JSONEncoder().encode(viewState.stack)
		UserDefaults.standard.set(viewStackData, forKey: "ViewStateStack")
		let viewHistoryData = try? JSONEncoder().encode(viewState.history)
		UserDefaults.standard.set(viewHistoryData, forKey: "ViewStateHistory")
		UserDefaults.standard.set(viewState.maxHistoryItems, forKey: "ViewStateHistoryMaxItems")
		
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
		sc.session.favorites?.addTrack(trackId: sc.player.playbackInfo.queue[sc.player.playbackInfo.currentIndex].track.id)
		favoriteLabel(currentIndex: sc.player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var removeFromFavorites: NSMenuItem!
	@IBAction func removeFromFavorites(_ sender: Any) {
		sc.session.favorites?.removeTrack(trackId: sc.player.playbackInfo.queue[sc.player.playbackInfo.currentIndex].track.id)
		favoriteLabel(currentIndex: sc.player.playbackInfo.currentIndex)
	}
	
	@IBOutlet weak var addToPlaylist: NSMenuItem!
	@IBAction func addToPlaylist(_ sender: Any) {
		print("Add to Playlist")
	}
	@IBOutlet weak var albumAddFavorites: NSMenuItem!
	@IBAction func albumAddFavorites(_ sender: Any) {
		sc.session.favorites?.addAlbum(albumId: sc.player.playbackInfo.queue[sc.player.playbackInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: sc.player.playbackInfo.currentIndex)
	}
	@IBOutlet weak var albumRemoveFavorites: NSMenuItem!
	@IBAction func albumRemoveFavorites(_ sender: Any) {
		sc.session.favorites?.removeAlbum(albumId: sc.player.playbackInfo.queue[sc.player.playbackInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: sc.player.playbackInfo.currentIndex)
	}
	
	func favoriteLabel(currentIndex: Int) {
		if sc.player.playbackInfo.queue.isEmpty {
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
		
		let trackIsInFavorites = sc.player.playbackInfo.queue[currentIndex].track.isInFavorites(session: sc.session)
		if trackIsInFavorites != nil && trackIsInFavorites! {
			addToFavorites.isHidden = true
			removeFromFavorites.isHidden = false
		} else {
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
		}
		
		if trackIsInFavorites != nil && trackIsInFavorites! {
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
		sc.player.togglePlay()
	}
	func playLabel(playing: Bool) {
		if playing {
			play.title = "Pause"
		} else {
			play.title = "Play"
		}
	}
	@IBAction func stop(_ sender: Any) {
		sc.player.stop()
	}
	@IBAction func next(_ sender: Any) {
		sc.player.next()
	}
	@IBAction func previous(_ sender: Any) {
		sc.player.previous()
	}
	
	@IBAction func increaseVolume(_ sender: Any) {
		sc.player.increaseVolume()
	}
	@IBAction func decreaseVolume(_ sender: Any) {
		sc.player.decreaseVolume()
	}
	@IBOutlet weak var mute: NSMenuItem!
	@IBAction func mute(_ sender: Any) {
		sc.player.toggleMute()
	}
	func muteState(volume: Float) {
		mute.state = volume == 0 ? .on : .off
	}
	
	@IBOutlet weak var shuffle: NSMenuItem!
	@IBAction func shuffle(_ sender: Any) {
		sc.player.playbackInfo.shuffle.toggle()
	}
	func shuffleState(enabled: Bool) {
		shuffle.state = enabled ? .on : .off
	}
	
	@IBAction func toggleRepeat(_ sender: Any) {
		sc.player.playbackInfo.repeatState = sc.player.playbackInfo.repeatState.next()
	}
	@IBOutlet weak var repeatOff: NSMenuItem!
	@IBAction func repeatOff(_ sender: Any) {
		sc.player.playbackInfo.repeatState = .off
	}
	@IBOutlet weak var repeatAll: NSMenuItem!
	@IBAction func repeatAll(_ sender: Any) {
		sc.player.playbackInfo.repeatState = .all
	}
	@IBOutlet weak var repeatSingle: NSMenuItem!
	@IBAction func repeatSingle(_ sender: Any) {
		sc.player.playbackInfo.repeatState = .single
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
		sc.player.clearQueue()
	}
	
	// MARK: - Account
	
	@IBAction func accountInfo(_ sender: Any) {
		guard let userId = sc.session.userId else { return }
		guard let title = sc.session.getUser(userId: userId)?.username else { return }
		let controller = ResizableWindowController(rootView:
			AccountInfoView(session: sc.session)
		)
		controller.window?.title = title
		controller.showWindow(nil)
	}
	@IBAction func logout(_ sender: Any) {
		logout()
	}
	
	// MARK: - Window
	
	@IBAction func lyrics(_ sender: Any) {
		lyricsViewController.showWindow(nil)
	}
	@IBAction func queue(_ sender: Any) {
		queueViewController.showWindow(nil)
	}
	
	@IBAction func viewHistory(_ sender: Any) {
		viewHistoryViewController.showWindow(nil)
	}
	
	@IBAction func playbackHistory(_ sender: Any) {
		playbackHistoryViewController.showWindow(nil)
	}
}

// MARK: - Extra functions

func secondsToHoursMinutesSecondsString(seconds: Int) -> String {
	let formatter = DateComponentsFormatter()
	formatter.allowedUnits = [.hour, .minute, .second]
	formatter.unitsStyle = .positional

	return formatter.string(from: TimeInterval(seconds))!
}

