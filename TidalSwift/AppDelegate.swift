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
import UpdateNotification

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var window: NSWindow!
	let updateNotification = UpdateNotification(feedUrl: URL(string: "http://www.melvin-gundlach.de/apps/app-feeds/TidalSwift.json")!)
	
	let session: Session
	let player: Player
	var viewState: ViewState
	var sortingState: SortingState
	var playlistEditingValues = PlaylistEditingValues()
	
	// Login
	let loginInfo = LoginInfo()
	
	// Secondary Windows
	var lyricsViewController: NSWindowController
	var queueViewController: NSWindowController
	var viewHistoryViewController: NSWindowController
	var playbackHistoryViewController: NSWindowController
	
	// MARK: Cancellables
	var timerCancellable: AnyCancellable?
	var savePlaybackInfoOnNextTick = false
	var saveViewStateOnNextTick = false
	var saveSortingStateOnNextTick = false
	
	var playingCancellable: AnyCancellable?
	var shuffleCancellable: AnyCancellable?
	var repeatCancellable: AnyCancellable?
	var pauseAfterCancellable: AnyCancellable?
	var queueCancellable: AnyCancellable?
	var currentIndexCancellable: AnyCancellable?
	var volumeCancellable: AnyCancellable?
	var viewStackCancellable: AnyCancellable?
	
	// SortingState
	var favoritePlaylistSortingCancellable: AnyCancellable?
	var favoritePlaylistReversedCancellable: AnyCancellable?
	var favoriteAlbumSortingCancellable: AnyCancellable?
	var favoriteAlbumReversedCancellable: AnyCancellable?
	var favoriteTrackSortingCancellable: AnyCancellable?
	var favoriteTrackReversedCancellable: AnyCancellable?
	var favoriteVideoSortingCancellable: AnyCancellable?
	var favoriteVideoReversedCancellable: AnyCancellable?
	var favoriteArtistSortingCancellable: AnyCancellable?
	var favoriteArtistReversedCancellable: AnyCancellable?
	
	var offlinePlaylistSortingCancellable: AnyCancellable?
	var offlinePlaylistReversedCancellable: AnyCancellable?
	var offlineAlbumSortingCancellable: AnyCancellable?
	var offlineAlbumReversedCancellable: AnyCancellable?
	var offlineTrackSortingCancellable: AnyCancellable?
	var offlineTrackReversedCancellable: AnyCancellable?
	
	// MARK: - Functions
	
	override init() {
		session = Session(config: nil)
		
		if let audioQualityString = UserDefaults.standard.string(forKey: "audioQuality"),
		   let audioQuality = AudioQuality(rawValue: audioQualityString) {
			player = Player(session: session, audioQuality: audioQuality)
		} else {
			player = Player(session: session, audioQuality: .hifi)
		}
		
		var cache = ViewCache()
		if let data = UserDefaults.standard.data(forKey: "ViewCache") {
			if let tempCache = try? JSONDecoder().decode(ViewCache.self, from: data) {
				cache = tempCache
			}
		}
		
		viewState = ViewState(session: session, cache: cache)
		sortingState = SortingState()
		
		// Init Secondary Windows (cannot use method func because self is not initialized yet
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
				.environmentObject(playlistEditingValues)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(
			rootView: PlaybackHistoryView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		playbackHistoryViewController.window?.title = "Playback History"
		
		super.init()
	}
	
	func initSecondaryWindows() {
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		lyricsViewController.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowController(rootView:
			QueueView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		queueViewController.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowController(
			rootView: PlaybackHistoryView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		playbackHistoryViewController.window?.title = "Playback History"
	}
	
	func closeAllSecondaryWindows() {
		lyricsViewController.close()
		queueViewController.close()
		viewHistoryViewController.close()
		playbackHistoryViewController.close()
	}
	
	func logout() {
		print("Logout")
		closeModals()
		closeAllSecondaryWindows()
		player.clearQueue()
		session.logout()
		viewState.clearEverything()
		loginInfo.showModal = true
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		session.helpers.offline.uiRefreshFunc = { [unowned self] in self.viewState.refreshCurrentView() }
		
		let loggedIn = session.loadSession()
//		let loggedIn = session.checkLogin()
		print("Login Succesful: \(loggedIn)")
		
		loginInfo.showModal = !loggedIn
		
		if loggedIn {
			// Retrieve Playback State
			if let data = UserDefaults.standard.data(forKey: "PlaybackInfo") {
				if let codablePI = try? JSONDecoder().decode(CodablePlaybackInfo.self, from: data) {
					// PlaybackInfo
					player.playbackInfo.volume = codablePI.volume
					player.playbackInfo.shuffle = codablePI.shuffle
					player.playbackInfo.repeatState = codablePI.repeatState
					player.playbackInfo.pauseAfter = codablePI.pauseAfter
					
					// QueueInfo
					player.queueInfo.nonShuffledQueue = codablePI.nonShuffledQueue
					player.queueInfo.queue = codablePI.queue
					player.queueInfo.history = codablePI.history
					player.queueInfo.maxHistoryItems = codablePI.maxHistoryItems
					
					player.play(atIndex: codablePI.currentIndex)
					player.pause()
					// TODO: Seeking at this point doesn't work. Why?
//					player.seek(to: Double(codablePI.fraction))
//					print("Wanted: \(Double(codablePI.fraction)), Actual: \(player.playbackInfo.fraction)")
				}
			}
			if let data = UserDefaults.standard.data(forKey: "SortingState") {
				if let codableSS = try? JSONDecoder().decode(CodableSortingState.self, from: data) {
					sortingState.favoritePlaylistSorting = codableSS.favoritePlaylistSorting
					sortingState.favoritePlaylistReversed = codableSS.favoritePlaylistReversed
					sortingState.favoriteAlbumSorting = codableSS.favoriteAlbumSorting
					sortingState.favoriteAlbumReversed = codableSS.favoriteAlbumReversed
					sortingState.favoriteTrackSorting = codableSS.favoriteTrackSorting
					sortingState.favoriteTrackReversed = codableSS.favoriteTrackReversed
					sortingState.favoriteVideoSorting = codableSS.favoriteVideoSorting
					sortingState.favoriteVideoReversed = codableSS.favoriteVideoReversed
					sortingState.favoriteArtistSorting = codableSS.favoriteArtistSorting
					sortingState.favoriteArtistReversed = codableSS.favoriteArtistReversed
					sortingState.offlinePlaylistSorting = codableSS.offlinePlaylistSorting
					sortingState.offlinePlaylistReversed = codableSS.offlinePlaylistReversed
					sortingState.offlineAlbumSorting = codableSS.offlineAlbumSorting
					sortingState.offlineAlbumReversed = codableSS.offlineAlbumReversed
					sortingState.offlineTrackSorting = codableSS.offlineTrackSorting
					sortingState.offlineTrackReversed = codableSS.offlineTrackReversed
				}
			}
			
			// Retrieve View Stack
			if let data = UserDefaults.standard.data(forKey: "ViewStateStack") {
				if let tempStack = try? JSONDecoder().decode([TidalSwiftView].self, from: data) {
					viewState.stack = tempStack
				}
			}
			if let searchTerm = UserDefaults.standard.string(forKey: "SearchTerm") {
				viewState.searchTerm = searchTerm
				viewState.lastSearchTerm = searchTerm
			}
			
			viewState.newReleasesIncludeEps = UserDefaults.standard.bool(forKey: "NewReleasesIncludeEps")
			
			if let data = UserDefaults.standard.data(forKey: "ViewStateHistory") {
				if let tempHistory = try? JSONDecoder().decode([TidalSwiftView].self, from: data) {
					viewState.history = tempHistory
				}
			}
			let tempMaxHistoryItems = UserDefaults.standard.integer(forKey: "ViewStateHistoryMaxItems")
			if tempMaxHistoryItems != 0 {
				viewState.maxHistoryItems = tempMaxHistoryItems
			} else {
				viewState.maxHistoryItems = 100
			}
		}
		
		// Space for Play/Pause
		// Currently deactivated, because no way to know, if currently writing text in a TextField
//		NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
//			if event.characters == " " { [unowned self] in
//				self.player.togglePlay()
//			}
//			return event
//		}
		
		// MARK: Combine Stuff
		
		initCancellables()
		
		viewState.refreshCurrentView()
		
		// Swift UI Stuff
		window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // Comment out the last if issue of content
			backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")
		
		window.contentView = NSHostingView(
			rootView: ContentView(loginInfo: loginInfo,
								  playlistEditingValues: playlistEditingValues,
								  viewState: viewState,
								  sortingState: sortingState,
								  session: session,
								  player: player)
		)
		window.title = "TidalSwift"
		window.makeKeyAndOrderFront(nil)
		
		updateCheck(showNoUpdatesAlert: false)
		
		session.helpers.offline.syncAllOfflinePlaylistsAndFavoriteTracks()
		
		// Shouldn't interfere with View State as the view doesn't replace the existing one if it's not New Releases
		DispatchQueue.global(qos: .background).async(execute: viewState.newReleasesWI)
		
		audioQualityLabel(audioQuality: player.nextAudioQuality)
		
		
		initSecondaryWindows()
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		true
	}
	
	func updateCheck(showNoUpdatesAlert: Bool) {
		DispatchQueue.global(qos: .background).async { [self] in
			if updateNotification.checkForUpdates() {
				DispatchQueue.main.async { [self] in
					updateNotification.showNewVersionView()
				}
			} else if showNoUpdatesAlert {
				DispatchQueue.main.async {
					let alert = NSAlert()
					alert.messageText = "No updates available"
					alert.informativeText = "You are already on the latest version"
					alert.alertStyle = .informational
					alert.addButton(withTitle: "OK")
					alert.runModal()
				}
			}
		}
	}
	
	func savePlaybackState() {
		let codablePI = CodablePlaybackInfo(fraction: player.playbackInfo.fraction,
											volume: player.playbackInfo.volume,
											shuffle: player.playbackInfo.shuffle,
											repeatState: player.playbackInfo.repeatState,
											pauseAfter: player.playbackInfo.pauseAfter,
											nonShuffledQueue: player.queueInfo.nonShuffledQueue,
											queue: player.queueInfo.queue,
											currentIndex: player.queueInfo.currentIndex,
											history: player.queueInfo.history,
											maxHistoryItems: player.queueInfo.maxHistoryItems)
		let playbackInfoData = try? JSONEncoder().encode(codablePI)
		UserDefaults.standard.set(playbackInfoData, forKey: "PlaybackInfo")
		
		UserDefaults.standard.set(player.nextAudioQuality.rawValue, forKey: "audioQuality")
	}
	
	func saveViewState() {
		UserDefaults.standard.set(viewState.searchTerm, forKey: "SearchTerm")
		UserDefaults.standard.set(viewState.newReleasesIncludeEps, forKey: "NewReleasesIncludeEps")
		let viewStackData = try? JSONEncoder().encode(viewState.stack)
		UserDefaults.standard.set(viewStackData, forKey: "ViewStateStack")
		let viewHistoryData = try? JSONEncoder().encode(viewState.history)
		UserDefaults.standard.set(viewHistoryData, forKey: "ViewStateHistory")
		UserDefaults.standard.set(viewState.maxHistoryItems, forKey: "ViewStateHistoryMaxItems")
	}
	
	func saveFavoritesSortingState() {
		let codableSS = CodableSortingState(favoritePlaylistSorting: sortingState.favoritePlaylistSorting,
													  favoritePlaylistReversed: sortingState.favoritePlaylistReversed,
													  favoriteAlbumSorting: sortingState.favoriteAlbumSorting,
													  favoriteAlbumReversed: sortingState.favoriteAlbumReversed,
													  favoriteTrackSorting: sortingState.favoriteTrackSorting,
													  favoriteTrackReversed: sortingState.favoriteTrackReversed,
													  favoriteVideoSorting: sortingState.favoriteVideoSorting,
													  favoriteVideoReversed: sortingState.favoriteVideoReversed,
													  favoriteArtistSorting: sortingState.favoriteArtistSorting,
													  favoriteArtistReversed: sortingState.favoriteArtistReversed,
													  offlinePlaylistSorting: sortingState.offlinePlaylistSorting,
													  offlinePlaylistReversed: sortingState.offlinePlaylistReversed,
													  offlineAlbumSorting: sortingState.offlineAlbumSorting,
													  offlineAlbumReversed: sortingState.offlinePlaylistReversed,
													  offlineTrackSorting: sortingState.offlineTrackSorting,
													  offlineTrackReversed: sortingState.offlineTrackReversed)
		let codableSSData = try? JSONEncoder().encode(codableSS)
		UserDefaults.standard.set(codableSSData, forKey: "SortingState")
	}
	
	func saveViewCache() {
		// View Cache
		let viewCacheData = try? JSONEncoder().encode(viewState.cache)
		UserDefaults.standard.set(viewCacheData, forKey: "ViewCache")
	}
	
	func saveState() {
		session.saveConfig()
		session.saveSession()
		savePlaybackState()
		saveViewState()
		saveViewCache()
		saveFavoritesSortingState()
	}
	
	func closeModals() {
		loginInfo.showModal = false
		playlistEditingValues.showAddTracksModal = false
		playlistEditingValues.showRemoveTracksModal = false
		playlistEditingValues.showDeleteModal = false
		playlistEditingValues.showEditModal = false
	}
	
	func initCancellables() {
		playingCancellable = player.playbackInfo.$playing.receive(on: DispatchQueue.main).sink(receiveValue: playLabel(playing:))
		shuffleCancellable = player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] in
			self.shuffleState(enabled: $0)
			self.savePlaybackInfoOnNextTick = true
		})
		repeatCancellable = player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self ] in
			self.repeatLabel(repeatState: $0)
			self.savePlaybackInfoOnNextTick = true
		})
		pauseAfterCancellable = player.playbackInfo.$pauseAfter.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] in
			self.pauseAfterState(enabled: $0)
			self.savePlaybackInfoOnNextTick = true
		})
		volumeCancellable = player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: muteState(volume:))
		
		queueCancellable = player.queueInfo.$queue.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in self.savePlaybackInfoOnNextTick = true })
		currentIndexCancellable = player.queueInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] in
			self.favoriteLabel(currentIndex: $0)
			self.savePlaybackInfoOnNextTick = true
		})
		
		viewStackCancellable = viewState.$stack.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
//			print("Save: ViewState")
			self.saveViewStateOnNextTick = true
		})
		
		// SortingState
		favoritePlaylistSortingCancellable = sortingState.$favoritePlaylistSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoritePlaylistReversedCancellable = sortingState.$favoritePlaylistReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteAlbumSortingCancellable = sortingState.$favoriteAlbumSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteAlbumReversedCancellable = sortingState.$favoriteAlbumReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteTrackSortingCancellable = sortingState.$favoriteTrackSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteTrackReversedCancellable = sortingState.$favoriteTrackReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteVideoSortingCancellable = sortingState.$favoriteVideoSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteVideoReversedCancellable = sortingState.$favoriteVideoReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteArtistSortingCancellable = sortingState.$favoriteArtistSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		favoriteArtistReversedCancellable = sortingState.$favoriteArtistReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		
		offlinePlaylistSortingCancellable = sortingState.$offlinePlaylistSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		offlinePlaylistReversedCancellable = sortingState.$offlinePlaylistReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		offlineAlbumSortingCancellable = sortingState.$offlineAlbumSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		offlineAlbumReversedCancellable = sortingState.$offlineAlbumReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		offlineTrackSortingCancellable = sortingState.$offlineTrackSorting.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		offlineTrackReversedCancellable = sortingState.$offlineTrackReversed.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
			self.saveSortingStateOnNextTick = true
		})
		
		// State Persisting
		timerCancellable = Timer.publish(every: 10, on: .main, in: .default)
			.autoconnect()
			.sink { [unowned self] _ in
				if self.savePlaybackInfoOnNextTick {
					self.savePlaybackInfoOnNextTick = false
//					print("savePlaybackState()")
					DispatchQueue.global(qos: .background).async {
						self.savePlaybackState()
					}
				}
				if self.saveViewStateOnNextTick {
					self.saveViewStateOnNextTick = false
//					print("saveViewState()")
					DispatchQueue.global(qos: .background).async {
						self.saveViewState()
					}
				}
				if self.saveSortingStateOnNextTick {
					self.saveSortingStateOnNextTick = false
//					print("saveFavoritesSortingState()")
					DispatchQueue.global(qos: .background).async {
						self.saveFavoritesSortingState()
					}
				}
			}
	}
	
	func cancelCancellables() {
		timerCancellable?.cancel()
		
		playingCancellable?.cancel()
		shuffleCancellable?.cancel()
		repeatCancellable?.cancel()
		pauseAfterCancellable?.cancel()
		
		queueCancellable?.cancel()
		currentIndexCancellable?.cancel()
		volumeCancellable?.cancel()
		
		viewStackCancellable?.cancel()
		
		// SortingState
		favoritePlaylistSortingCancellable?.cancel()
		favoritePlaylistReversedCancellable?.cancel()
		favoriteAlbumSortingCancellable?.cancel()
		favoriteAlbumReversedCancellable?.cancel()
		favoriteTrackSortingCancellable?.cancel()
		favoriteTrackReversedCancellable?.cancel()
		favoriteVideoSortingCancellable?.cancel()
		favoriteVideoReversedCancellable?.cancel()
		favoriteArtistSortingCancellable?.cancel()
		favoriteArtistReversedCancellable?.cancel()
	}
	
	// MARK: - Menu Bar
	// MARK: - TidalSwift
	
	@IBAction func checkForUpdates(_ sender: Any) {
		updateCheck(showNoUpdatesAlert: true)
	}
	
	@IBAction func changelog(_ sender: Any) {
		updateNotification.showChangelogWindow()
	}
	
	@IBAction func quit(_ sender: Any) {
		print("Exiting...")
		cancelCancellables()
		closeModals()
		saveState()
		NSApp.terminate(nil)
	}
	
	// MARK: - File
	
	@IBAction func downloadTrack(_ sender: Any) {
		print("Menu: downloadTrack")
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		DispatchQueue.global(qos: .background).async { [self] in
			_ = self.session.helpers.download.download(track: track, audioQuality: player.nextAudioQuality)
		}
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
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		viewState.push(album: track.album)
	}
	@IBOutlet weak var goToArtist: NSMenuItem!
	@IBAction func goToArtist(_ sender: Any) {
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		if !track.artists.isEmpty {
			print("Go to \(track.artists[0].name)")
			viewState.push(artist: track.artists[0])
		}
		// TODO: Not just the first artist
	}
	
	@IBOutlet weak var addToFavorites: NSMenuItem!
	@IBAction func addToFavorites(_ sender: Any) {
		session.favorites?.addTrack(trackId: player.queueInfo.queue[player.queueInfo.currentIndex].track.id)
		session.helpers.offline.asyncSyncFavoriteTracks()
		favoriteLabel(currentIndex: player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	@IBOutlet weak var removeFromFavorites: NSMenuItem!
	@IBAction func removeFromFavorites(_ sender: Any) {
		session.favorites?.removeTrack(trackId: player.queueInfo.queue[player.queueInfo.currentIndex].track.id)
		session.helpers.offline.asyncSyncFavoriteTracks()
		favoriteLabel(currentIndex: player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	
	@IBOutlet weak var addToPlaylist: NSMenuItem!
	@IBAction func addToPlaylist(_ sender: Any) {
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		print("Add \(track.title) to Playlist")
		playlistEditingValues.tracks = [track]
		playlistEditingValues.showAddTracksModal = true
	}
	@IBOutlet weak var albumAddFavorites: NSMenuItem!
	@IBAction func albumAddFavorites(_ sender: Any) {
		session.favorites?.addAlbum(albumId: player.queueInfo.queue[player.queueInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	@IBOutlet weak var albumRemoveFavorites: NSMenuItem!
	@IBAction func albumRemoveFavorites(_ sender: Any) {
		session.favorites?.removeAlbum(albumId: player.queueInfo.queue[player.queueInfo.currentIndex].track.album.id)
		favoriteLabel(currentIndex: player.queueInfo.currentIndex)
		viewState.refreshCurrentView()
	}
	
	func favoriteLabel(currentIndex: Int) {
		if player.queueInfo.queue.isEmpty {
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
		}
		
		goToAlbum.isEnabled = true
		goToArtist.isEnabled = true
		addToFavorites.isEnabled = true
		addToPlaylist.isEnabled = true
		albumAddFavorites.isEnabled = true
		
		let trackIsInFavorites = player.queueInfo.queue[currentIndex].track.isInFavorites(session: session)
		if trackIsInFavorites ?? false {
			addToFavorites.isHidden = true
			removeFromFavorites.isHidden = false
		} else {
			addToFavorites.isHidden = false
			removeFromFavorites.isHidden = true
		}
		
		let albumIsInFavorites = player.queueInfo.queue[currentIndex].track.album.isInFavorites(session: session)
		if albumIsInFavorites ?? false {
			albumAddFavorites.isHidden = true
			albumRemoveFavorites.isHidden = false
		} else {
			albumAddFavorites.isHidden = false
			albumRemoveFavorites.isHidden = true
			albumAddFavorites.isEnabled = true
		}
	}
	
	@IBAction func addQueueToPlaylist(_ sender: Any) {
		let tracks = player.queueInfo.queue.unwrapped()
		print("Add \(tracks.count) to Playlist")
		playlistEditingValues.tracks = tracks
		playlistEditingValues.showAddTracksModal = true
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
	
	@IBAction func toggleRepeat(_ sender: Any) {
		player.playbackInfo.repeatState = player.playbackInfo.repeatState.next()
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
	
	@IBOutlet weak var pauseAfterCurrentTrack: NSMenuItem!
	@IBAction func pauseAfterCurrentTrack(_ sender: Any) {
		player.playbackInfo.pauseAfter.toggle()
	}
	func pauseAfterState(enabled: Bool) {
		pauseAfterCurrentTrack.state = enabled ? .on : .off
	}
	
	@IBOutlet weak var audioQualityLow: NSMenuItem!
	@IBAction func audioQualityLow(_ sender: Any) {
		player.setAudioQuality(to: .low)
		audioQualityLabel(audioQuality: .low)
	}
	@IBOutlet weak var audioQualityHigh: NSMenuItem!
	@IBAction func audioQualityHigh(_ sender: Any) {
		player.setAudioQuality(to: .high)
		audioQualityLabel(audioQuality: .high)
	}
	@IBOutlet weak var audioQualityHiFi: NSMenuItem!
	@IBAction func audioQualityHiFi(_ sender: Any) {
		player.setAudioQuality(to: .hifi)
		audioQualityLabel(audioQuality: .hifi)
		
	}
	func audioQualityLabel(audioQuality: AudioQuality) {
		switch audioQuality {
		case .low:
			audioQualityLow.state = .on
			audioQualityHigh.state = .off
			audioQualityHiFi.state = .off
		case .high:
			audioQualityLow.state = .off
			audioQualityHigh.state = .on
			audioQualityHiFi.state = .off
		case .hifi:
			audioQualityLow.state = .off
			audioQualityHigh.state = .off
			audioQualityHiFi.state = .on
		case .master:
			break
		}
		savePlaybackInfoOnNextTick = true
	}
	
	@IBAction func clearQueue(_ sender: Any) {
		player.clearQueue(leavingCurrent: true)
	}
	
	// MARK: - Account
	
	@IBAction func accountInfo(_ sender: Any) {
		guard let userId = session.userId else { return }
		guard let title = session.getUser(userId: userId)?.username else { return }
		let controller = ResizableWindowController(rootView:
			AccountInfoView(session: session)
		)
		controller.window?.title = title
		controller.showWindow(nil)
	}
	@IBAction func refreshAccessToken(_ sender: Any) {
		session.refreshAccessToken()
	}
	@IBAction func logout(_ sender: Any) {
		removeAllOfflineContent(self)
		logout()
	}
	@IBAction func removeAllOfflineContent(_ sender: Any) {
		session.helpers.offline.removeAll()
		viewState.clearEverything() // Also clears Cache
	}
	
	// MARK: - Window
	
	@IBAction func lyrics(_ sender: Any) {
		lyricsViewController.showWindow(nil)
	}
	@IBAction func queue(_ sender: Any) {
		queueViewController.showWindow(nil)
	}
	
	@IBAction func playbackHistory(_ sender: Any) {
		playbackHistoryViewController.showWindow(nil)
	}
	
	@IBAction func viewHistory(_ sender: Any) {
		viewHistoryViewController.showWindow(nil)
	}
}
