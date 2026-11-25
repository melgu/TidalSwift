//
//  TrackList.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "TrackList")

/// Tracks, or the tracks and videos of a playlist. Videos open in a window of their own and aren't added to the queue.
struct TrackList: View {
	let items: [PlaylistItem]
	/// The tracks of the items, which are played
	private let tracks: [Track]
	let showCover: Bool
	let showAlbumTrackNumber: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let playlist: Playlist? // Has to be nil if not displaying User Playlist
	let session: Session
	let player: Player
	
	init(tracks: [Track], showCover: Bool, showAlbumTrackNumber: Bool, showArtist: Bool, showAlbum: Bool, playlist: Playlist?, session: Session, player: Player) {
		self.init(
			items: tracks.map(PlaylistItem.track), showCover: showCover, showAlbumTrackNumber: showAlbumTrackNumber,
			showArtist: showArtist, showAlbum: showAlbum, playlist: playlist, session: session, player: player
		)
	}
	
	init(items: [PlaylistItem], showCover: Bool, showAlbumTrackNumber: Bool, showArtist: Bool, showAlbum: Bool, playlist: Playlist?, session: Session, player: Player) {
		self.items = items
		self.tracks = items.compactMap(\.track)
		self.showCover = showCover
		self.showAlbumTrackNumber = showAlbumTrackNumber
		self.showArtist = showArtist
		self.showAlbum = showAlbum
		self.playlist = playlist
		self.session = session
		self.player = player
	}
	
	var body: some View {
		LazyVStack {
			ForEach(Array(items.enumerated()), id: \.offset) { index, item in
				switch item {
				case .track(let track):
					TrackRow(track: track, showCover: showCover, showArtist: showArtist, showAlbum: showAlbum, trackNumber: showAlbumTrackNumber ? nil : index, session: session)
					.contentShape(.rect)
					.onTapGesture(count: 2) {
						play(track, at: index)
					}
					.accessibilityAction {
						play(track, at: index)
					}
					.contextMenu {
						TrackContextMenu(track: track, indexInPlaylist: playlist != nil ? index : nil, playlist: playlist, session: session, player: player)
					}
				case .video(let video):
					VideoRow(video: video, showArtist: showArtist, showAlbum: showAlbum, session: session)
					.contentShape(.rect)
					.onTapGesture(count: 2) {
						play(video)
					}
					.accessibilityAction {
						play(video)
					}
					.contextMenu {
						VideoContextMenu(video: video, indexInPlaylist: playlist != nil ? index : nil, playlist: playlist, session: session, player: player)
					}
				}
				Divider()
			}
		}
		.padding(.horizontal)
	}
	
	/// - Parameter index: The position among the items, videos included
	private func play(_ track: Track, at index: Int) {
		guard track.isPlayable else { return }
		logger.debug("\(track.id) \(track.title)")
		let trackIndex = items[..<index].count { $0.track != nil }
		player.add(tracks: tracks, .now, playAt: trackIndex)
	}
	
	private func play(_ video: Video) {
		guard video.streamReady else { return }
		logger.debug("Video \(video.id) \(video.title)")
		#if canImport(AppKit)
		Task {
			await player.play(video: video)
		}
		#endif
	}
}

/// Column widths, as fractions of the row
private struct ColumnWidths {
	let title: CGFloat
	let artist: CGFloat
	let album: CGFloat
	
	init(showArtist: Bool, showAlbum: Bool) {
		if showArtist && showAlbum { // Both
			(title, artist, album) = (0.28, 0.28, 0.28)
		} else if showArtist != showAlbum { // One
			(title, artist, album) = (0.40, 0.40, 0.40)
		} else { // None
			(title, artist, album) = (0.66, 0.0, 0.0)
		}
	}
}

/// A video among the tracks of a playlist
private struct VideoRow: View {
	let video: Video
	let showArtist: Bool
	let showAlbum: Bool
	let session: Session
	
	@Environment(ViewState.self) private var viewState
	@Environment(Offline.self) private var offline
	@Environment(FavoritesState.self) private var favoritesState
	
	private var widths: ColumnWidths {
		ColumnWidths(showArtist: showArtist, showAlbum: showAlbum)
	}
	
	var body: some View {
		GeometryReader { metrics in
			HStack {
				HStack {
					HStack {
						if let imageUrl = video.imageUrl(session: session, resolution: 160) {
							AsyncImage(url: imageUrl)
							.aspectRatio(contentMode: .fill)
							.frame(width: 30, height: 30)
							.clipped()
							.cornerRadius(CORNERRADIUS)
							.accessibilityHidden(true)
						} else {
							Rectangle()
								.fill(.black)
								.frame(width: 30, height: 30)
								.cornerRadius(CORNERRADIUS)
						}
						HStack(spacing: 4) {
							Text(video.title)
							Image(systemName: "play.rectangle")
								.secondaryIconColor()
								.accessibilityLabel("Video")
								.help("Video")
								.layoutPriority(1)
							if video.explicit {
								Text("􀂝")
									.foregroundStyle(.secondary)
									.layoutPriority(1)
							}
						}
						Spacer(minLength: 5)
					}
					.frame(width: metrics.size.width * widths.title)
					.help("\(video.title) – \(video.artists.formArtistString())")
					if showArtist {
						HStack {
							Text(video.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widths.artist)
						.help(video.artists.formArtistString())
					}
					if showAlbum {
						Spacer(minLength: 0)
							.frame(width: metrics.size.width * widths.album)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: video.duration))
					Spacer()
					if offline.isVideoOffline(video: video) {
						Image(systemName: "arrow.down.circle.fill")
							.secondaryIconColor()
					}
					Button {
						Task {
							if favoritesState.contains(video: video) {
								logger.debug("Remove video from Favorites")
								if await favoritesState.removeVideo(videoId: video.id) {
									viewState.refreshCurrentView()
								}
							} else {
								logger.debug("Add video to Favorites")
								await favoritesState.addVideo(videoId: video.id)
							}
						}
					} label: {
						Image(systemName: favoritesState.contains(video: video) ? "heart.fill" : "heart")
							.accessibilityLabel("Favorite")
							.accessibilityAddTraits(favoritesState.contains(video: video) ? .isSelected : [])
					}
					.buttonStyle(.plain)
				}
			}
			.foregroundStyle(video.streamReady ? .primary : .secondary)
		}
		.lineLimit(1)
		.frame(height: 30)
	}
}

private struct TrackRow: View {
	let track: Track
	let showCover: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let trackNumber: Int?
	let session: Session
	
	private let widths: ColumnWidths
	
	@Environment(ViewState.self) private var viewState
	@Environment(QueueInfo.self) private var queueInfo
	@Environment(Offline.self) private var offline
	@Environment(FavoritesState.self) private var favoritesState
	@State private var isOffline: Bool = false
	
	init(track: Track, showCover: Bool = false, showArtist: Bool, showAlbum: Bool,
		 trackNumber: Int? = nil, session: Session) {
		self.track = track
		self.showCover = showCover
		self.showArtist = showArtist
		self.showAlbum = showAlbum
		if let trackNumber = trackNumber {
			self.trackNumber = trackNumber + 1 // To start counting from 1
		} else {
			self.trackNumber = nil
		}
		self.session = session
		self.widths = ColumnWidths(showArtist: showArtist, showAlbum: showAlbum)
	}
	
	var body: some View {
		GeometryReader { metrics in
			HStack {
				HStack {
					HStack {
						if !queueInfo.queue.isEmpty &&
							queueInfo.queue[queueInfo.currentIndex] == track {
							Image(systemName: "play.fill")
								.secondaryIconColor()
						}
						if showCover {
							if let coverUrl = track.getCoverUrl(session: session, resolution: 80) {
								AsyncImage(url: coverUrl)
								.frame(width: 30, height: 30)
								.cornerRadius(CORNERRADIUS)
								.accessibilityHidden(true)
							} else {
								Rectangle()
									.fill(.black)
									.frame(width: 30, height: 30)
									.cornerRadius(CORNERRADIUS)
							}
						} else {
							Text("\(trackNumber ?? track.trackNumber)")
								.fontWeight(.thin)
								.foregroundStyle(.secondary)
						}
						HStack(spacing: 4) {
							Text(track.title)
							if let version = track.version {
								Text(version)
									.foregroundStyle(.secondary)
									.layoutPriority(-1)
							}
							if track.hasAttributes {
								track.attributeHStack
									.layoutPriority(1)
							}
						}
						Spacer(minLength: 5)
					}
					.frame(width: metrics.size.width * widths.title)
					.help(trackToolTipString)
					if showArtist {
						HStack {
							Text(track.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widths.artist)
						.help(track.artists.formArtistString())
					}
					if showAlbum {
						HStack {
							Text(track.album.title)
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widths.album)
						.help(track.album.title)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: track.duration))
					Spacer()
					if isOffline {
						Image(systemName: "arrow.down.circle.fill")
							.secondaryIconColor()
					}
					#if canImport(AppKit)
					Button {
						let controller = ResizableWindowControllerFactory.create(rootView:
							CreditsView(session: session, track: track)
								.environment(viewState)
						)
						controller.window?.title = "Credits – \(track.title)"
						controller.showWindow(nil)
					} label: {
						Image(systemName: "c.circle")
							.accessibilityLabel("Credits")
							.help("Credits")
					}
					.buttonStyle(.plain)
					#endif
					Button {
						if favoritesState.contains(track: track) {
							logger.debug("Remove from Favorites")
							Task {
								if await favoritesState.removeTrack(trackId: track.id) {
									offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
							}
						} else {
							logger.debug("Add to Favorites")
							Task {
								if await favoritesState.addTrack(trackId: track.id) {
									offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
							}
						}
					} label: {
						Image(systemName: favoritesState.contains(track: track) ? "heart.fill" : "heart")
							.accessibilityLabel("Favorite")
							.accessibilityAddTraits(favoritesState.contains(track: track) ? .isSelected : [])
					}
					.buttonStyle(.plain)
				}
			}
		.foregroundStyle(track.isPlayable ? .primary : .secondary)
		.task(id: track.id) {
			isOffline = offline.isTrackOffline(track: track)
		}
	}
		.lineLimit(1)
		.frame(height: showCover ? 30 : 16) // Values tested "by hand"
	}
	
	private var trackToolTipString: String {
		var s = track.title
		if let version = track.version {
			s += " (\(version))"
		}
		s += " – \(track.artists.formArtistString())"
		return s
	}
}
