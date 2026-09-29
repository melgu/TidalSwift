//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import UpdateNotification

@main
struct TidalSwiftApp: App {
	@State private var appModel = TidalSwiftAppModel()
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some Scene {
		WindowGroup("TidalSwift") {
			ContentView(
				loginInfo: appModel.loginInfo,
				playlistEditingValues: appModel.playlistEditingValues,
				viewState: appModel.viewState,
				sortingState: appModel.sortingState,
				session: appModel.session,
				player: appModel.player
			)
			.environment(appModel)
			.onAppear {
				appModel.startupIfNeeded()
			}
			.onChange(of: scenePhase) { _, newValue in
				if newValue != .active {
					appModel.saveState()
				}
			}
		}
		.commands {
			TidalSwiftCommands(appModel: appModel)
		}
	}
}

@Observable
final class TidalSwiftAppModel {
	@ObservationIgnored private let updateNotification = UpdateNotification(feedUrl: URL(string: "https://www.melvin-gundlach.de/apps/app-feeds/TidalSwift.json")!)
	
	let session: Session
	let player: Player
	var viewState: ViewState
	var sortingState: SortingState
	var playlistEditingValues = PlaylistEditingValues()
	let loginInfo = LoginInfo()
	
	private var didStart = false
	private var isTerminating = false
	
	#if canImport(AppKit)
	private var lyricsViewController: NSWindowController?
	private var queueViewController: NSWindowController?
	private var viewHistoryViewController: NSWindowController?
	private var playbackHistoryViewController: NSWindowController?
	#endif
	
	@ObservationIgnored private var saveTask: Task<Void, Never>?
	
	var trackIsFavorite = false
	var albumIsFavorite = false
	
	// The offline settings live in the non-observable library, so the menus read these copies
	private(set) var offlineAudioQuality: AudioQuality
	private(set) var offlinePreferDolbyAtmos: Bool
	
	var hasCurrentTrack: Bool {
		!player.queueInfo.queue.isEmpty
	}
	
	init() {
		session = Session(config: nil)
		
		let preferDolbyAtmos = UserDefaults.standard.bool(forKey: "preferDolbyAtmos")
		// Only High is offered, so a stored Low or Low 320 falls back to it as well
		player = Player(session: session, audioQuality: .high, preferDolbyAtmos: preferDolbyAtmos)
		
		var cache = ViewCache()
		if let data = UserDefaults.standard.data(forKey: "ViewCache") {
			if let tempCache = try? JSONDecoder().decode(ViewCache.self, from: data) {
				cache = tempCache
			}
		}
		
		viewState = ViewState(session: session, cache: cache)
		sortingState = SortingState()
		
		offlineAudioQuality = session.config.offlineAudioQuality
		offlinePreferDolbyAtmos = session.helpers.offline.preferDolbyAtmos
	}
	
	func startupIfNeeded() {
		guard !didStart else { return }
		didStart = true
		startup()
	}
	
	private func startup() {
		session.helpers.offline.uiRefreshFunc = { [weak self] in
			self?.viewState.refreshCurrentView()
		}
		
		let loggedIn = session.loadSession()
		print("Login Succesful: \(loggedIn)")
		loginInfo.showModal = !loggedIn
		
		if loggedIn {
			restorePlaybackState()
			restoreSortingState()
			restoreViewState()
		}
		
		player.queueInfo.onCurrentTrackChange = { [weak self] in
			self?.refreshFavoriteState()
		}
		startSaveLoop()
		viewState.refreshCurrentView()
		refreshFavoriteState()
		
		#if canImport(AppKit)
		initSecondaryWindows()
		registerTerminationBehavior()
		registerCloseLastWindowBehavior()
		
		updateCheck(showNoUpdatesAlert: false)
		#endif
		
		Task {
			await session.helpers.offline.syncAllOfflinePlaylistsAndFavoriteTracks()
		}
		
		Task {
			await viewState.refreshNewReleases()
		}
	}
	
	#if canImport(AppKit)
	private func prepareForTermination() {
		guard !isTerminating else { return }
		isTerminating = true
		saveTask?.cancel()
		closeModals()
		saveState()
	}
	
	func quit() {
		prepareForTermination()
		NSApp.terminate(nil)
	}
	
	private func registerTerminationBehavior() {
		// Not an async sequence: its elements arrive after the app has already terminated
		_ = NotificationCenter.default.addObserver(
			forName: NSApplication.willTerminateNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			// Safe because the observer asks for delivery on the main queue
			MainActor.assumeIsolated {
				self?.prepareForTermination()
			}
		}
	}
	
	private func registerCloseLastWindowBehavior() {
		if #available(macOS 27, *) {
			_ = NotificationCenter.default.addObserver(of: NSWindow.self, for: .willClose) { [weak self] message in
				self?.quitIfLastWindow(closing: message.window)
			}
		} else {
			_ = NotificationCenter.default.addObserver(
				forName: NSWindow.willCloseNotification,
				object: nil,
				queue: .main
			) { [weak self] notification in
				let closingWindow = notification.object as? NSWindow
				// Safe because the observer asks for delivery on the main queue
				MainActor.assumeIsolated {
					self?.quitIfLastWindow(closing: closingWindow)
				}
			}
		}
	}
	
	private func quitIfLastWindow(closing closingWindow: NSWindow?) {
		guard !isTerminating else { return }
		// The closing window still counts as visible while the notification is
		// being delivered, so ignore it and look for any other visible one
		let hasOtherVisibleWindow = NSApp.windows.contains { $0.isVisible && $0 !== closingWindow }
		if !hasOtherVisibleWindow {
			quit()
		}
	}
	
	// MARK: Secondary Windows
	
	private func initSecondaryWindows() {
		lyricsViewController = ResizableWindowControllerFactory.create(rootView:
			LyricsView(session: session)
				.environment(viewState)
				.environment(player.queueInfo)
		)
		lyricsViewController?.window?.title = "Lyrics"
		
		queueViewController = ResizableWindowControllerFactory.create(rootView:
			QueueView(session: session, player: player)
				.environment(viewState)
				.environment(player.queueInfo)
				.environment(playlistEditingValues)
		)
		queueViewController?.window?.title = "Queue"
		
		viewHistoryViewController = ResizableWindowControllerFactory.create(rootView:
			ViewHistoryView()
				.environment(viewState)
		)
		viewHistoryViewController?.window?.title = "View History"
		
		playbackHistoryViewController = ResizableWindowControllerFactory.create(
			rootView: PlaybackHistoryView(session: session, player: player)
				.environment(viewState)
				.environment(player.queueInfo)
		)
		playbackHistoryViewController?.window?.title = "Playback History"
	}
	
	private func closeAllSecondaryWindows() {
		lyricsViewController?.close()
		queueViewController?.close()
		viewHistoryViewController?.close()
		playbackHistoryViewController?.close()
	}
	
	func showLyricsWindow() {
		lyricsViewController?.showWindow(nil)
	}
	
	func showQueueWindow() {
		queueViewController?.showWindow(nil)
	}
	
	func showPlaybackHistoryWindow() {
		playbackHistoryViewController?.showWindow(nil)
	}
	
	func showViewHistoryWindow() {
		viewHistoryViewController?.showWindow(nil)
	}
	#endif
	
	// MARK: Persisting
	
	private func restorePlaybackState() {
		if let data = UserDefaults.standard.data(forKey: "PlaybackInfo") {
			if let codablePI = try? JSONDecoder().decode(CodablePlaybackInfo.self, from: data) {
				player.playbackInfo.volume = codablePI.volume
				player.playbackInfo.shuffle = codablePI.shuffle
				player.playbackInfo.repeatState = codablePI.repeatState
				player.playbackInfo.pauseAfter = codablePI.pauseAfter
				
				player.queueInfo.nonShuffledQueue = codablePI.nonShuffledQueue
				player.queueInfo.queue = codablePI.queue
				player.queueInfo.history = codablePI.history
				player.queueInfo.maxHistoryItems = codablePI.maxHistoryItems
				
				player.play(atIndex: codablePI.currentIndex)
				player.pause()
			}
		}
	}
	
	private func restoreSortingState() {
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
	}
	
	private func restoreViewState() {
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
	
	private func savePlaybackState() {
		let codablePI = CodablePlaybackInfo(
			fraction: player.playbackInfo.fraction,
			volume: player.playbackInfo.volume,
			shuffle: player.playbackInfo.shuffle,
			repeatState: player.playbackInfo.repeatState,
			pauseAfter: player.playbackInfo.pauseAfter,
			nonShuffledQueue: player.queueInfo.nonShuffledQueue,
			queue: player.queueInfo.queue,
			currentIndex: player.queueInfo.currentIndex,
			history: player.queueInfo.history,
			maxHistoryItems: player.queueInfo.maxHistoryItems
		)
		let playbackInfoData = try? JSONEncoder().encode(codablePI)
		UserDefaults.standard.set(playbackInfoData, forKey: "PlaybackInfo")
		UserDefaults.standard.set(player.nextAudioQuality.rawValue, forKey: "audioQuality")
		UserDefaults.standard.set(player.preferDolbyAtmos, forKey: "preferDolbyAtmos")
	}
	
	private func saveViewState() {
		UserDefaults.standard.set(viewState.searchTerm, forKey: "SearchTerm")
		UserDefaults.standard.set(viewState.newReleasesIncludeEps, forKey: "NewReleasesIncludeEps")
		let viewStackData = try? JSONEncoder().encode(viewState.stack)
		UserDefaults.standard.set(viewStackData, forKey: "ViewStateStack")
		let viewHistoryData = try? JSONEncoder().encode(viewState.history)
		UserDefaults.standard.set(viewHistoryData, forKey: "ViewStateHistory")
		UserDefaults.standard.set(viewState.maxHistoryItems, forKey: "ViewStateHistoryMaxItems")
	}
	
	private func saveFavoritesSortingState() {
		let codableSS = CodableSortingState(
			favoritePlaylistSorting: sortingState.favoritePlaylistSorting,
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
			offlineTrackReversed: sortingState.offlineTrackReversed
		)
		let codableSSData = try? JSONEncoder().encode(codableSS)
		UserDefaults.standard.set(codableSSData, forKey: "SortingState")
	}
	
	private func saveViewCache() {
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
	
	private func closeModals() {
		loginInfo.showModal = false
		playlistEditingValues.showAddTracksModal = false
		playlistEditingValues.showRemoveTracksModal = false
		playlistEditingValues.showDeleteModal = false
		playlistEditingValues.showEditModal = false
	}
	
	private func startSaveLoop() {
		saveTask = Task { [weak self] in
			while !Task.isCancelled {
				do {
					try await Task.sleep(for: .seconds(10))
				} catch {
					return
				}
				self?.saveUnsavedChanges()
			}
		}
	}
	
	private func saveUnsavedChanges() {
		if player.playbackInfo.hasUnsavedChanges || player.queueInfo.hasUnsavedChanges {
			player.playbackInfo.hasUnsavedChanges = false
			player.queueInfo.hasUnsavedChanges = false
			savePlaybackState()
		}
		if viewState.hasUnsavedChanges {
			viewState.hasUnsavedChanges = false
			saveViewState()
		}
		if sortingState.hasUnsavedChanges {
			sortingState.hasUnsavedChanges = false
			saveFavoritesSortingState()
		}
	}
	
	// MARK: Menu Actions
	
	#if canImport(AppKit)
	func checkForUpdates() {
		updateCheck(showNoUpdatesAlert: true)
	}
	#endif
	
	func showChangelog() {
		#if canImport(AppKit)
		updateNotification.showChangelogWindow()
		#else
		print("Not implemented")
		#endif
	}
	
	#if canImport(AppKit)
	private func updateCheck(showNoUpdatesAlert: Bool) {
		Task {
			do {
				if try await updateNotification.checkForUpdates() {
					updateNotification.showNewVersionView()
				} else if showNoUpdatesAlert {
					let alert = NSAlert()
					alert.messageText = "No updates available"
					alert.informativeText = "You are already on the latest version"
					alert.alertStyle = .informational
					alert.addButton(withTitle: "OK")
					alert.runModal()
				}
			} catch {
				print("Checking for updates failed: \(error)")
			}
		}
	}
	#endif
	
	func downloadTrack() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex]
		Task { [self] in
			_ = await session.helpers.download.download(track: track)
		}
	}
	
	func goToAlbum() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex]
		viewState.push(album: track.album)
	}
	
	func goToArtist() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex]
		guard !track.artists.isEmpty else { return }
		viewState.push(artist: track.artists[0])
	}
	
	func addCurrentTrackToFavorites() {
		guard hasCurrentTrack else { return }
		let trackId = player.queueInfo.queue[player.queueInfo.currentIndex].id
		Task {
			if await session.favorites?.addTrack(trackId: trackId) == true {
				session.helpers.offline.asyncSyncFavoriteTracks()
				refreshFavoriteState()
				viewState.refreshCurrentView()
			}
		}
	}
	
	func removeCurrentTrackFromFavorites() {
		guard hasCurrentTrack else { return }
		let trackId = player.queueInfo.queue[player.queueInfo.currentIndex].id
		Task {
			if await session.favorites?.removeTrack(trackId: trackId) == true {
				session.helpers.offline.asyncSyncFavoriteTracks()
				refreshFavoriteState()
				viewState.refreshCurrentView()
			}
		}
	}
	
	func addCurrentTrackToPlaylist() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex]
		playlistEditingValues.tracks = [track]
		playlistEditingValues.showAddTracksModal = true
	}
	
	func addCurrentAlbumToFavorites() {
		guard hasCurrentTrack else { return }
		let albumId = player.queueInfo.queue[player.queueInfo.currentIndex].album.id
		Task {
			if await session.favorites?.addAlbum(albumId: albumId) == true {
				refreshFavoriteState()
				viewState.refreshCurrentView()
			}
		}
	}
	
	func removeCurrentAlbumFromFavorites() {
		guard hasCurrentTrack else { return }
		let albumId = player.queueInfo.queue[player.queueInfo.currentIndex].album.id
		Task {
			if await session.favorites?.removeAlbum(albumId: albumId) == true {
				refreshFavoriteState()
				viewState.refreshCurrentView()
			}
		}
	}
	
	func addQueueToPlaylist() {
		let tracks = player.queueInfo.queue
		playlistEditingValues.tracks = tracks
		playlistEditingValues.showAddTracksModal = true
	}
	
	func togglePlay() {
		player.togglePlay()
	}
	
	func stop() {
		player.stop()
	}
	
	func next() {
		player.next()
	}
	
	func previous() {
		player.previous()
	}
	
	func increaseVolume() {
		player.increaseVolume()
	}
	
	func decreaseVolume() {
		player.decreaseVolume()
	}
	
	func toggleMute() {
		player.toggleMute()
	}
	
	func toggleShuffle() {
		player.playbackInfo.shuffle.toggle()
	}
	
	func setRepeatState(_ repeatState: RepeatState) {
		player.playbackInfo.repeatState = repeatState
	}
	
	func togglePauseAfterCurrentTrack() {
		player.playbackInfo.pauseAfter.toggle()
	}
	
	func setAudioQuality(_ audioQuality: AudioQuality) {
		player.setAudioQuality(to: audioQuality)
		player.playbackInfo.hasUnsavedChanges = true
	}
	
	func setOfflineAudioQuality(_ audioQuality: AudioQuality) {
		session.helpers.offline.setAudioQuality(to: audioQuality)
		offlineAudioQuality = session.config.offlineAudioQuality
	}
	
	func toggleOfflinePreferDolbyAtmos() {
		session.helpers.offline.setPreferDolbyAtmos(to: !session.helpers.offline.preferDolbyAtmos)
		offlinePreferDolbyAtmos = session.helpers.offline.preferDolbyAtmos
	}
	
	func togglePreferDolbyAtmos() {
		player.setPreferDolbyAtmos(to: !player.preferDolbyAtmos)
		player.playbackInfo.hasUnsavedChanges = true
	}
	
	func clearQueue() {
		player.clearQueue(leavingCurrent: true)
	}
	
	func accountInfo() {
		#if canImport(AppKit)
		guard let userId = session.userId else { return }
		Task {
			guard let user = await session.user(userId: userId) else { return }
			let controller = ResizableWindowControllerFactory.create(rootView:
				AccountInfoView(session: session)
			)
			controller.window?.title = user.username
			controller.showWindow(nil)
		}
		#else
		print("Coming soon")
		#endif
	}
	
	func refreshAccessToken() {
		Task {
			do {
				try await session.refreshAccessToken()
			} catch {
				print("Refresh Access Token failed. Error: \(error)")
			}
		}
	}
	
	func logout() {
		session.helpers.offline.removeAll()
		closeModals()
		#if canImport(AppKit)
		closeAllSecondaryWindows()
		#endif
		player.clearQueue()
		session.logout()
		viewState.clearEverything()
		loginInfo.showModal = true
		trackIsFavorite = false
		albumIsFavorite = false
	}
	
	func removeAllOfflineContent() {
		Task {
			session.helpers.offline.removeAll()
			viewState.clearEverything()
		}
	}
	
	private func refreshFavoriteState() {
		guard hasCurrentTrack else {
			trackIsFavorite = false
			albumIsFavorite = false
			return
		}
		
		let track = player.queueInfo.queue[player.queueInfo.currentIndex]
		Task {
			let trackFavorite = await track.isInFavorites(session: session) ?? false
			let albumFavorite = await track.album.isInFavorites(session: session) ?? false
			self.trackIsFavorite = trackFavorite
			self.albumIsFavorite = albumFavorite
		}
	}
}

private struct TidalSwiftCommands: Commands {
	let appModel: TidalSwiftAppModel
	@FocusedValue(\.searchFieldFocus) private var searchFieldFocus
	
	var body: some Commands {
		#if canImport(AppKit)
		CommandGroup(after: .appInfo) {
			Button("Check for Updates") {
				appModel.checkForUpdates()
			}
			Button("Changelog") {
				appModel.showChangelog()
			}
		}
		
		CommandGroup(replacing: .appTermination) {
			Button("Quit TidalSwift") {
				appModel.quit()
			}
			.keyboardShortcut("q", modifiers: .command)
		}
		#endif
		
		CommandMenu("Track") {
			Button("Go to Album") {
				appModel.goToAlbum()
			}
			.disabled(!appModel.hasCurrentTrack)
			
			Button("Go to Artist") {
				appModel.goToArtist()
			}
			.disabled(!appModel.hasCurrentTrack)
				
				if appModel.trackIsFavorite {
					Button("Remove from Favorites") {
						appModel.removeCurrentTrackFromFavorites()
					}
					.disabled(!appModel.hasCurrentTrack)
				} else {
					Button("Add to Favorites") {
						appModel.addCurrentTrackToFavorites()
					}
					.disabled(!appModel.hasCurrentTrack)
				}
			
			Button("Add to Playlist") {
				appModel.addCurrentTrackToPlaylist()
			}
			.disabled(!appModel.hasCurrentTrack)
				
				if appModel.albumIsFavorite {
					Button("Remove Album from Favorites") {
						appModel.removeCurrentAlbumFromFavorites()
					}
					.disabled(!appModel.hasCurrentTrack)
				} else {
					Button("Add Album to Favorites") {
						appModel.addCurrentAlbumToFavorites()
					}
					.disabled(!appModel.hasCurrentTrack)
				}
			
			Button("Add Queue to Playlist") {
				appModel.addQueueToPlaylist()
			}
			.disabled(appModel.player.queueInfo.queue.isEmpty)
		}
		
		CommandMenu("Control") {
			Button(appModel.player.playbackInfo.playing ? "Pause" : "Play") {
				appModel.togglePlay()
			}
			.keyboardShortcut(.space, modifiers: []) // Explicit empty modifiers required because of implicit CMD modifier
			.disabled(!appModel.hasCurrentTrack)
			Button("Stop") {
				appModel.stop()
			}
			.keyboardShortcut(".", modifiers: .command)
			.disabled(!appModel.hasCurrentTrack)
			Button("Next") {
				appModel.next()
			}
			.keyboardShortcut(.rightArrow, modifiers: .command)
			.disabled(!appModel.hasCurrentTrack)
			Button("Previous") {
				appModel.previous()
			}
			.keyboardShortcut(.leftArrow, modifiers: .command)
			.disabled(!appModel.hasCurrentTrack)
			
			Divider()
			
			Button("Increase Volume") {
				appModel.increaseVolume()
			}
			.keyboardShortcut(.upArrow, modifiers: .command)
			Button("Decrease Volume") {
				appModel.decreaseVolume()
			}
			.keyboardShortcut(.downArrow, modifiers: .command)
			Toggle("Mute", isOn: Binding(
				get: { appModel.player.playbackInfo.volume == 0 },
				set: { _ in appModel.toggleMute() }
			))
			
			Divider()
			
			Toggle("Shuffle", isOn: Binding(
				get: { appModel.player.playbackInfo.shuffle },
				set: { _ in appModel.toggleShuffle() }
			))
			
			Picker("Repeat", selection: Binding(
				get: { appModel.player.playbackInfo.repeatState },
				set: { appModel.setRepeatState($0) }
			)) {
				Text("Off").tag(RepeatState.off)
				Text("All").tag(RepeatState.all)
				Text("Single").tag(RepeatState.single)
			}
			
			Toggle("Pause After Current Track", isOn: Binding(
				get: { appModel.player.playbackInfo.pauseAfter },
				set: { _ in appModel.togglePauseAfterCurrentTrack() }
			))
			
			Button("Clear Queue") {
				appModel.clearQueue()
			}
			.disabled(appModel.player.queueInfo.queue.isEmpty)
			
			Divider()
			
			Menu("Audio Quality") {
				Picker("Audio Quality", selection: Binding(
					get: { appModel.player.nextAudioQuality },
					set: { appModel.setAudioQuality($0) }
				)) {
					// Low and Low 320 only come as DASH streams encrypted with Widevine and PlayReady DRM
//					Text("Low (96 kbps)").tag(AudioQuality.low)
//					Text("Low (320 kbps)").tag(AudioQuality.medium)
					Text("High (Lossless)").tag(AudioQuality.high)
					// Max isn't delivered to this client, see AudioQuality
//					Text("Max (Hi-Res Lossless)").tag(AudioQuality.max)
				}
				.pickerStyle(.inline)
				.labelsHidden()
				
				Divider()
				
				Toggle("Prefer Dolby Atmos", isOn: Binding(
					get: { appModel.player.preferDolbyAtmos },
					set: { _ in appModel.togglePreferDolbyAtmos() }
				))
			}
			
			Menu("Offline Audio Quality") {
				Picker("Offline Audio Quality", selection: Binding(
					get: { appModel.offlineAudioQuality },
					set: { appModel.setOfflineAudioQuality($0) }
				)) {
					// Same options as Audio Quality, see there
//					Text("Low (96 kbps)").tag(AudioQuality.low)
//					Text("Low (320 kbps)").tag(AudioQuality.medium)
					Text("High (Lossless)").tag(AudioQuality.high)
//					Text("Max (Hi-Res Lossless)").tag(AudioQuality.max)
				}
				.pickerStyle(.inline)
				.labelsHidden()
				
				Divider()
				
				Toggle("Prefer Dolby Atmos", isOn: Binding(
					get: { appModel.offlinePreferDolbyAtmos },
					set: { _ in appModel.toggleOfflinePreferDolbyAtmos() }
				))
			}
		}
		
		CommandMenu("Account") {
			Button("Account Info") {
				appModel.accountInfo()
			}
			Button("Refresh Access Token") {
				appModel.refreshAccessToken()
			}
			Button("Logout") {
				appModel.logout()
			}
			Button("Remove All Offline Content") {
				appModel.removeAllOfflineContent()
			}
		}
		
		#if canImport(AppKit)
		CommandGroup(after: .windowArrangement) {
			Divider()
			Button("Lyrics") {
				appModel.showLyricsWindow()
			}
			.keyboardShortcut("l", modifiers: .command)
			Button("Queue") {
				appModel.showQueueWindow()
			}
			.keyboardShortcut("p", modifiers: .command)
			Button("Playback History") {
				appModel.showPlaybackHistoryWindow()
			}
			.keyboardShortcut("k", modifiers: .command)
			Button("View History") {
				appModel.showViewHistoryWindow()
			}
			.keyboardShortcut("u", modifiers: .command)
		}
		#endif
		
		CommandGroup(after: .textEditing) {
			Button("Find") {
				searchFieldFocus?.wrappedValue = true
			}
			.keyboardShortcut("f", modifiers: .command)
			.disabled(searchFieldFocus == nil)
		}
		
		CommandGroup(after: .newItem) {
			Button("Download Track") {
				appModel.downloadTrack()
			}
			.disabled(!appModel.hasCurrentTrack)
		}
	}
}
