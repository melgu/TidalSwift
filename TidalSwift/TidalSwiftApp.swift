//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib
import UpdateNotification

@main
struct TidalSwiftApp: App {
	@StateObject private var appModel = TidalSwiftAppModel()
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
			.environmentObject(appModel)
			.onAppear {
				appModel.startupIfNeeded()
			}
			#if canImport(AppKit)
			.onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
				appModel.prepareForTermination()
			}
			#endif
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

final class TidalSwiftAppModel: ObservableObject {
	let updateNotification = UpdateNotification(feedUrl: URL(string: "https://www.melvin-gundlach.de/apps/app-feeds/TidalSwift.json")!)

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
	private var windowCloseObserver: NSObjectProtocol?
	#endif

	// MARK: Cancellables
	var timerCancellable: AnyCancellable?
	var savePlaybackInfoOnNextTick = false
	var saveViewStateOnNextTick = false
	var saveSortingStateOnNextTick = false
	var uiRefreshCancellable: AnyCancellable?

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

	@Published var trackIsFavorite = false
	@Published var albumIsFavorite = false

	var hasCurrentTrack: Bool {
		!player.queueInfo.queue.isEmpty
	}

	init() {
		session = Session(config: nil)

		if let audioQualityString = UserDefaults.standard.string(forKey: "audioQuality"),
		   let audioQuality = AudioQuality(rawValue: audioQualityString) {
			player = Player(session: session, audioQuality: audioQuality)
		} else {
			player = Player(session: session, audioQuality: .high)
		}

		var cache = ViewCache()
		if let data = UserDefaults.standard.data(forKey: "ViewCache") {
			if let tempCache = try? JSONDecoder().decode(ViewCache.self, from: data) {
				cache = tempCache
			}
		}

		viewState = ViewState(session: session, cache: cache)
		sortingState = SortingState()
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

		initCancellables()
		viewState.refreshCurrentView()
		refreshFavoriteState()
		
		#if canImport(AppKit)
		initSecondaryWindows()
		registerCloseLastWindowBehavior()
		
		updateCheck(showNoUpdatesAlert: false)
		#endif

		Task {
			await session.helpers.offline.syncAllOfflinePlaylistsAndFavoriteTracks()
		}

		DispatchQueue.global(qos: .background).async(execute: viewState.newReleasesWI)
	}
	
	#if canImport(AppKit)
	func prepareForTermination() {
		guard !isTerminating else { return }
		isTerminating = true
		if let windowCloseObserver {
			NotificationCenter.default.removeObserver(windowCloseObserver)
			self.windowCloseObserver = nil
		}
		cancelCancellables()
		closeModals()
		saveState()
	}
	
	func quit() {
		prepareForTermination()
		NSApp.terminate(nil)
	}

	private func registerCloseLastWindowBehavior() {
		windowCloseObserver = NotificationCenter.default.addObserver(
			forName: NSWindow.willCloseNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			guard let self else { return }
			DispatchQueue.main.async {
				if !self.isTerminating && !NSApp.windows.contains(where: { $0.isVisible }) {
					self.quit()
				}
			}
		}
	}

	// MARK: Secondary Windows

	func initSecondaryWindows() {
		lyricsViewController = ResizableWindowController(rootView:
			LyricsView()
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		lyricsViewController?.window?.title = "Lyrics"

		queueViewController = ResizableWindowController(rootView:
			QueueView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
				.environmentObject(playlistEditingValues)
		)
		queueViewController?.window?.title = "Queue"

		viewHistoryViewController = ResizableWindowController(rootView:
			ViewHistoryView()
				.environmentObject(viewState)
		)
		viewHistoryViewController?.window?.title = "View History"

		playbackHistoryViewController = ResizableWindowController(
			rootView: PlaybackHistoryView(session: session, player: player)
				.environmentObject(viewState)
				.environmentObject(player.queueInfo)
		)
		playbackHistoryViewController?.window?.title = "Playback History"
	}

	func closeAllSecondaryWindows() {
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

	func savePlaybackState() {
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

	func saveViewCache() {
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
		uiRefreshCancellable = Publishers.Merge(player.playbackInfo.objectWillChange, player.queueInfo.objectWillChange)
			.sink { [weak self] _ in
				self?.objectWillChange.send()
			}

		shuffleCancellable = player.playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
		}
		repeatCancellable = player.playbackInfo.$repeatState.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
		}
		pauseAfterCancellable = player.playbackInfo.$pauseAfter.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
		}
		volumeCancellable = player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
		}

		queueCancellable = player.queueInfo.$queue.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
			self?.refreshFavoriteState()
		}
		currentIndexCancellable = player.queueInfo.$currentIndex.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.savePlaybackInfoOnNextTick = true
			self?.refreshFavoriteState()
		}

		viewStackCancellable = viewState.$stack.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.saveViewStateOnNextTick = true
		}

		favoritePlaylistSortingCancellable = sortingState.$favoritePlaylistSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoritePlaylistReversedCancellable = sortingState.$favoritePlaylistReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteAlbumSortingCancellable = sortingState.$favoriteAlbumSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteAlbumReversedCancellable = sortingState.$favoriteAlbumReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteTrackSortingCancellable = sortingState.$favoriteTrackSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteTrackReversedCancellable = sortingState.$favoriteTrackReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteVideoSortingCancellable = sortingState.$favoriteVideoSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteVideoReversedCancellable = sortingState.$favoriteVideoReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteArtistSortingCancellable = sortingState.$favoriteArtistSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		favoriteArtistReversedCancellable = sortingState.$favoriteArtistReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }

		offlinePlaylistSortingCancellable = sortingState.$offlinePlaylistSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		offlinePlaylistReversedCancellable = sortingState.$offlinePlaylistReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		offlineAlbumSortingCancellable = sortingState.$offlineAlbumSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		offlineAlbumReversedCancellable = sortingState.$offlineAlbumReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		offlineTrackSortingCancellable = sortingState.$offlineTrackSorting.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }
		offlineTrackReversedCancellable = sortingState.$offlineTrackReversed.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.saveSortingStateOnNextTick = true }

		timerCancellable = Timer.publish(every: 10, on: .main, in: .default)
			.autoconnect()
			.sink { [weak self] _ in
				guard let self else { return }
				if self.savePlaybackInfoOnNextTick {
					self.savePlaybackInfoOnNextTick = false
					DispatchQueue.global(qos: .background).async {
						self.savePlaybackState()
					}
				}
				if self.saveViewStateOnNextTick {
					self.saveViewStateOnNextTick = false
					DispatchQueue.global(qos: .background).async {
						self.saveViewState()
					}
				}
				if self.saveSortingStateOnNextTick {
					self.saveSortingStateOnNextTick = false
					DispatchQueue.global(qos: .background).async {
						self.saveFavoritesSortingState()
					}
				}
			}
	}

	func cancelCancellables() {
		timerCancellable?.cancel()
		uiRefreshCancellable?.cancel()
		shuffleCancellable?.cancel()
		repeatCancellable?.cancel()
		pauseAfterCancellable?.cancel()
		queueCancellable?.cancel()
		currentIndexCancellable?.cancel()
		volumeCancellable?.cancel()
		viewStackCancellable?.cancel()

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
	func updateCheck(showNoUpdatesAlert: Bool) {
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

	func find() {
		print("Find. Coming soon.")
	}

	func downloadTrack() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		Task { [self] in
			_ = await session.helpers.download.download(track: track, audioQuality: player.nextAudioQuality)
		}
	}

	func goToAlbum() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		viewState.push(album: track.album)
	}

	func goToArtist() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		guard !track.artists.isEmpty else { return }
		viewState.push(artist: track.artists[0])
	}

	func addCurrentTrackToFavorites() {
		guard hasCurrentTrack else { return }
		let trackId = player.queueInfo.queue[player.queueInfo.currentIndex].track.id
		Task {
			if await session.favorites?.addTrack(trackId: trackId) == true {
				session.helpers.offline.asyncSyncFavoriteTracks()
				await MainActor.run {
					refreshFavoriteState()
					viewState.refreshCurrentView()
				}
			}
		}
	}

	func removeCurrentTrackFromFavorites() {
		guard hasCurrentTrack else { return }
		let trackId = player.queueInfo.queue[player.queueInfo.currentIndex].track.id
		Task {
			if await session.favorites?.removeTrack(trackId: trackId) == true {
				session.helpers.offline.asyncSyncFavoriteTracks()
				await MainActor.run {
					refreshFavoriteState()
					viewState.refreshCurrentView()
				}
			}
		}
	}

	func addCurrentTrackToPlaylist() {
		guard hasCurrentTrack else { return }
		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		playlistEditingValues.tracks = [track]
		playlistEditingValues.showAddTracksModal = true
	}

	func addCurrentAlbumToFavorites() {
		guard hasCurrentTrack else { return }
		let albumId = player.queueInfo.queue[player.queueInfo.currentIndex].track.album.id
		Task {
			if await session.favorites?.addAlbum(albumId: albumId) == true {
				await MainActor.run {
					refreshFavoriteState()
					viewState.refreshCurrentView()
				}
			}
		}
	}

	func removeCurrentAlbumFromFavorites() {
		guard hasCurrentTrack else { return }
		let albumId = player.queueInfo.queue[player.queueInfo.currentIndex].track.album.id
		Task {
			if await session.favorites?.removeAlbum(albumId: albumId) == true {
				await MainActor.run {
					refreshFavoriteState()
					viewState.refreshCurrentView()
				}
			}
		}
	}

	func addQueueToPlaylist() {
		let tracks = player.queueInfo.queue.unwrapped()
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
		savePlaybackInfoOnNextTick = true
		objectWillChange.send()
	}

	func isAudioQualitySelected(_ audioQuality: AudioQuality) -> Bool {
		player.nextAudioQuality == audioQuality
	}

	func clearQueue() {
		player.clearQueue(leavingCurrent: true)
	}
	
	func accountInfo() {
		#if canImport(AppKit)
		guard let userId = session.userId else { return }
		Task {
			guard let user = await session.user(userId: userId) else { return }
			let controller = ResizableWindowController(rootView:
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
			await session.refreshAccessToken()
		}
	}

	func logout() {
		Task {
			await session.helpers.offline.removeAll()
			await MainActor.run {
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
		}
	}

	func removeAllOfflineContent() {
		Task {
			await session.helpers.offline.removeAll()
			await MainActor.run {
				viewState.clearEverything()
			}
		}
	}

	func refreshFavoriteState() {
		guard hasCurrentTrack else {
			trackIsFavorite = false
			albumIsFavorite = false
			return
		}

		let track = player.queueInfo.queue[player.queueInfo.currentIndex].track
		Task {
			let trackFavorite = await track.isInFavorites(session: session) ?? false
			let albumFavorite = await track.album.isInFavorites(session: session) ?? false
			self.trackIsFavorite = trackFavorite
			self.albumIsFavorite = albumFavorite
		}
	}
}

struct TidalSwiftCommands: Commands {
	@ObservedObject var appModel: TidalSwiftAppModel

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
			.keyboardShortcut("q")
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
			Button("Stop") {
				appModel.stop()
			}
			Button("Next") {
				appModel.next()
			}
			Button("Previous") {
				appModel.previous()
			}

			Divider()

			Button("Increase Volume") {
				appModel.increaseVolume()
			}
			Button("Decrease Volume") {
				appModel.decreaseVolume()
			}
			Toggle("Mute", isOn: Binding(
				get: { appModel.player.playbackInfo.volume == 0 },
				set: { _ in appModel.toggleMute() }
			))

			Divider()

			Toggle("Shuffle", isOn: Binding(
				get: { appModel.player.playbackInfo.shuffle },
				set: { _ in appModel.toggleShuffle() }
			))

			Menu("Repeat") {
				repeatButton(title: "Off", repeatState: .off)
				repeatButton(title: "All", repeatState: .all)
				repeatButton(title: "Single", repeatState: .single)
			}

			Toggle("Pause After Current Track", isOn: Binding(
				get: { appModel.player.playbackInfo.pauseAfter },
				set: { _ in appModel.togglePauseAfterCurrentTrack() }
			))

			Menu("Audio Quality") {
				audioQualityButton(title: "Low", quality: .low)
				audioQualityButton(title: "High", quality: .medium)
				audioQualityButton(title: "HiFi", quality: .high)
			}

			Button("Clear Queue") {
				appModel.clearQueue()
			}
			.disabled(appModel.player.queueInfo.queue.isEmpty)
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
			Button("Queue") {
				appModel.showQueueWindow()
			}
			Button("Playback History") {
				appModel.showPlaybackHistoryWindow()
			}
			Button("View History") {
				appModel.showViewHistoryWindow()
			}
		}
		#endif

		CommandMenu("Edit") {
			Button("Find") {
				appModel.find()
			}
			.keyboardShortcut("f")
		}

		CommandGroup(after: .newItem) {
			Button("Download Track") {
				appModel.downloadTrack()
			}
			.disabled(!appModel.hasCurrentTrack)
		}
	}

	@ViewBuilder
	private func repeatButton(title: String, repeatState: RepeatState) -> some View {
		Button {
			appModel.setRepeatState(repeatState)
		} label: {
			if appModel.player.playbackInfo.repeatState == repeatState {
				Label(title, systemImage: "checkmark")
			} else {
				Text(title)
			}
		}
	}

	@ViewBuilder
	private func audioQualityButton(title: String, quality: AudioQuality) -> some View {
		Button {
			appModel.setAudioQuality(quality)
		} label: {
			if appModel.isAudioQualitySelected(quality) {
				Label(title, systemImage: "checkmark")
			} else {
				Text(title)
			}
		}
	}
}
