//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine
import TidalSwiftLib

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var window: NSWindow!
	
	var sc: SessionContainer
	var viewState: ViewState
	var playlistEditingValues = PlaylistEditingValues()
	
	// Login
	let loginInfo = LoginInfo()
	
	// Secondary Windows
	var lyricsViewController: NSWindowController
	var queueViewController: NSWindowController
	var viewHistoryViewController: NSWindowController
	var playbackHistoryViewController: NSWindowController
	
	var timerCancellable: AnyCancellable?
	var savePlaybackInfoOnNextTick = false
	var saveViewStateOnNextTick = false
	
	override init() {
		let session = Session(config: nil)
		let player = Player(session: session)
		sc = SessionContainer(session: session, player: player)
		
		var cache = ViewCache()
		if let data = UserDefaults.standard.data(forKey: "ViewCache") {
			if let tempCache = try? JSONDecoder().decode(ViewCache.self, from: data) {
				cache = tempCache
			}
		}
		
		viewState = ViewState(session: session, cache: cache)
		
		// Init Secondary Windows (cannot use method func because self is not initialized yet
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(viewState)
				.environmentObject(sc.player.queueInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: sc.session, player: sc.player)
				.environmentObject(viewState)
				.environmentObject(sc)
				.environmentObject(sc.player.queueInfo)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(rootView:
			PlaybackHistoryView()
				.environmentObject(viewState)
				.environmentObject(sc)
				.environmentObject(sc.player.queueInfo)
		)
		playbackHistoryViewController.window?.title = "Playback History"
		
		super.init()
	}
	
	func initSecondaryWindows() {
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(viewState)
				.environmentObject(sc.player.queueInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: sc.session, player: sc.player)
				.environmentObject(viewState)
				.environmentObject(sc)
				.environmentObject(sc.player.queueInfo)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(rootView:
			PlaybackHistoryView()
				.environmentObject(viewState)
				.environmentObject(sc)
				.environmentObject(sc.player.queueInfo)
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
		viewState.clearQueue()
		loginInfo.showModal = true
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		let loggedIn = sc.session.loadSession()
//		let loggedIn = sc.session.checkLogin()
		print("Login Succesful: \(loggedIn)")
		
		loginInfo.showModal = !loggedIn
		
		if loggedIn {
			// Retrieve Playback State
			if let data = UserDefaults.standard.data(forKey: "PlaybackInfo") {
				if let tempPI = try? JSONDecoder().decode(CodablePlaybackInfo.self, from: data) {
					// PlaybackInfo
					sc.player.playbackInfo.volume = tempPI.volume
					sc.player.playbackInfo.shuffle = tempPI.shuffle
					sc.player.playbackInfo.repeatState = tempPI.repeatState
					
					// QueueInfo
					sc.player.queueInfo.nonShuffledQueue = tempPI.nonShuffledQueue
					sc.player.queueInfo.queue = tempPI.queue
					sc.player.queueInfo.history = tempPI.history
					sc.player.queueInfo.maxHistoryItems = tempPI.maxHistoryItems
					
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
						viewState.searchTerm = tempStack.last!.searchTerm
					}
				}
			}
			viewState.searchTerm = UserDefaults.standard.string(forKey: "SearchTerm") ?? ""
			
			if let data = UserDefaults.standard.data(forKey: "ViewStateHistory") {
				if let tempHistory = try? JSONDecoder().decode([TidalSwiftView].self, from: data) {
					viewState.history = tempHistory
				}
			}
			viewState.maxHistoryItems = UserDefaults.standard.integer(forKey: "ViewStateHistoryMaxItems")
		}
		
		// Space for Play/Pause
		// Currently deactivated, because no way to know, if currently writing text in a TextField
//		NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
//			if event.characters == " " { [unowned self] in
//				self.player.togglePlay()
//			}
//			return event
//		}
		
		// Combine Stuff
		_ = sc.player.playbackInfo.$playing.receive(on: DispatchQueue.main).sink(receiveValue: playLabel(playing:))
		_ = sc.player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffleState(enabled:))
		_ = sc.player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: repeatLabel(repeatState:))
		_ = sc.player.queueInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: favoriteLabel(currentIndex:))
		_ = sc.player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: muteState(volume:))
		
		// State Persisting
		timerCancellable = Timer.publish(every: 10, on: .main, in: .default)
			.autoconnect()
			.sink { _ in
				if self.savePlaybackInfoOnNextTick {
					self.savePlaybackInfoOnNextTick = false
					print("savePlaybackState()")
					DispatchQueue.global(qos: .background).async {
						self.savePlaybackState()
					}
				}
				if self.saveViewStateOnNextTick {
					self.saveViewStateOnNextTick = false
					print("saveViewStateSync()")
					DispatchQueue.global(qos: .background).async {
						self.saveViewState()
					}
				}
		}
		_ = sc.player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.savePlaybackInfoOnNextTick = true })
		_ = sc.player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.savePlaybackInfoOnNextTick = true })
		_ = sc.player.queueInfo.$queue.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.savePlaybackInfoOnNextTick = true })
		_ = sc.player.queueInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.savePlaybackInfoOnNextTick = true })
		
		_ = viewState.$stack.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.saveViewStateOnNextTick = true })
		
		// Combine Debug Stuff
//		_ = viewState.$viewType.receive(on: DispatchQueue.main).sink(receiveValue: { print("viewState Type: \($0?.rawValue ?? "nil")") })
//		_ = sc.$session.receive(on: DispatchQueue.main).sink(receiveValue: { _ in print("sc.session sink") })
//		_ = sc.$player.receive(on: DispatchQueue.main).sink(receiveValue: { _ in print("sc.player sink") })
		
		viewState.refreshCurrentView()
		
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
	
	func savePlaybackState() {
		let codablePI = CodablePlaybackInfo(fraction: sc.player.playbackInfo.fraction,
											volume: sc.player.playbackInfo.volume,
											shuffle: sc.player.playbackInfo.shuffle,
											repeatState: sc.player.playbackInfo.repeatState,
											nonShuffledQueue: sc.player.queueInfo.nonShuffledQueue,
											queue: sc.player.queueInfo.queue,
											currentIndex: sc.player.queueInfo.currentIndex,
											history: sc.player.queueInfo.history,
											maxHistoryItems: sc.player.queueInfo.maxHistoryItems)
		let playbackInfoData = try? JSONEncoder().encode(codablePI)
		UserDefaults.standard.set(playbackInfoData, forKey: "PlaybackInfo")
		
		UserDefaults.standard.synchronize()
	}
	
	func saveViewState() {
		UserDefaults.standard.set(viewState.searchTerm, forKey: "SearchTerm")
		let viewStackData = try? JSONEncoder().encode(viewState.stack)
		UserDefaults.standard.set(viewStackData, forKey: "ViewStateStack")
		let viewHistoryData = try? JSONEncoder().encode(viewState.history)
		UserDefaults.standard.set(viewHistoryData, forKey: "ViewStateHistory")
		UserDefaults.standard.set(viewState.maxHistoryItems, forKey: "ViewStateHistoryMaxItems")
		
		UserDefaults.standard.synchronize()
	}
	
	func saveViewCache() {
		// View Cache
		let viewCacheData = try? JSONEncoder().encode(viewState.cache)
		UserDefaults.standard.set(viewCacheData, forKey: "ViewCache")
		
		UserDefaults.standard.synchronize()
	}
	
	func saveState() {
		savePlaybackState()
		saveViewState()
		saveViewCache()
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
		timerCancellable?.cancel()
		closeModals()
		saveState()
		NSApp.terminate(nil)
	}
	
	// MARK: File
	
	@IBAction func downloadTrack(_ sender: Any) {
		print("Menu: downloadTrack")
		let track = sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track
		_ = sc.session.helpers?.download(track: track)
	}
	@IBAction func downloadAlbum(_ sender: Any) {
		print("Menu: downloadAlbum")
	}
	@IBAction func downloadPlaylist(_ sender: Any) {
		print("Menu: downloadPlaylist")
	}
	
	@IBOutlet weak var albumToggleOffline: NSMenuItem!
	@IBAction func albumToggleOffline(_ sender: Any) {
//		albumToggleOffline.state = albumToggleOffline.state == .on ? .off : .on
	}
	@IBOutlet weak var trackToggleOffline: NSMenuItem!
	@IBAction func trackToggleOffline(_ sender: Any) {
//		trackToggleOffline.state = trackToggleOffline.state == .on ? .off : .on
	}
	@IBOutlet weak var playlistToggleOffline: NSMenuItem!
	@IBAction func playlistToggleOffline(_ sender: Any) {
//		playlistToggleOffline.state = playlistToggleOffline.state == .on ? .off : .on
	}
	
	// MARK: - Edit
	
	@IBAction func find(_ sender: Any) {
		print("Find")
	}
	
	// MARK: - Track
	
	@IBOutlet weak var goToAlbum: NSMenuItem!
	@IBAction func goToAlbum(_ sender: Any) {
		print("Go to Album")
		let track = sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track
		viewState.push(album: track.album)
	}
	@IBOutlet weak var goToArtist: NSMenuItem!
	@IBAction func goToArtist(_ sender: Any) {
		let track = sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track
		if !track.artists.isEmpty {
			print("Go to \(track.artists[0].name)")
			viewState.push(artist: track.artists[0])
		}
		// TODO: Not just the first artist
	}
	
	@IBOutlet weak var addToFavorites: NSMenuItem!
	@IBAction func addToFavorites(_ sender: Any) {
		sc.session.favorites?.addTrack(trackId: sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track.id)
		sc.session.helpers?.offline.syncFavoriteTracks()
		favoriteLabel(currentIndex: sc.player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	@IBOutlet weak var removeFromFavorites: NSMenuItem!
	@IBAction func removeFromFavorites(_ sender: Any) {
		sc.session.favorites?.removeTrack(trackId: sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track.id)
		sc.session.helpers?.offline.syncFavoriteTracks()
		favoriteLabel(currentIndex: sc.player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	
	@IBOutlet weak var addToPlaylist: NSMenuItem!
	@IBAction func addToPlaylist(_ sender: Any) {
		let track = sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track
		print("Add \(track.title) to Playlist")
		self.playlistEditingValues.tracks = [track]
		self.playlistEditingValues.showAddTracksModal = true
	}
	@IBOutlet weak var albumAddFavorites: NSMenuItem!
	@IBAction func albumAddFavorites(_ sender: Any) {
		sc.session.favorites?.addAlbum(albumId: sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: sc.player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	@IBOutlet weak var albumRemoveFavorites: NSMenuItem!
	@IBAction func albumRemoveFavorites(_ sender: Any) {
		sc.session.favorites?.removeAlbum(albumId: sc.player.queueInfo.queue[sc.player.queueInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: sc.player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	
	func favoriteLabel(currentIndex: Int) {
		if sc.player.queueInfo.queue.isEmpty {
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
		
		let trackIsInFavorites = sc.player.queueInfo.queue[currentIndex].track.isInFavorites(session: sc.session)
		if trackIsInFavorites != nil && trackIsInFavorites! {
			addToFavorites.isHidden = true
			removeFromFavorites.isHidden = false
		} else {
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
		}
		
		let albumIsInFavorites = sc.player.queueInfo.queue[currentIndex].track.album.isInFavorites(session: sc.session)
		if albumIsInFavorites != nil && albumIsInFavorites! {
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
	@IBAction func removeAllOfflineContent(_ sender: Any) {
		sc.session.helpers?.offline.removeAll()
		viewState.refreshCurrentView()
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

