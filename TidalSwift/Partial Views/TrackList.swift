//
//  TrackList.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct TrackList: View {
	let tracks: [Track]
	let showCover: Bool
	let showAlbumTrackNumber: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let playlist: Playlist? // Has to be nil if not displaying User Playlist
	let session: Session
	let player: Player
	
	var body: some View {
		LazyVStack {
			ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
				TrackRow(track: track, showCover: showCover, showArtist: showArtist, showAlbum: showAlbum,
						 trackNumber: showAlbumTrackNumber ? nil : index, session: session)
				.onTapGesture(count: 2) {
					play(track, at: index)
				}
				.accessibilityAction {
					play(track, at: index)
				}
				.contextMenu {
					TrackContextMenu(track: track, indexInPlaylist: playlist != nil ? index : nil, playlist: playlist, session: session, player: player)
				}
				Divider()
			}
		}
		.padding(.horizontal)
	}
	
	private func play(_ track: Track, at index: Int) {
		if track.isUnavailable { return }
		print("\(track.id) \(track.title)")
		player.add(tracks: tracks, .now, playAt: index)
	}
}

private struct TrackRow: View {
	let track: Track
	let showCover: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let trackNumber: Int?
	let session: Session
	
	private var widthFactorTrack: CGFloat
	private var widthFactorArtist: CGFloat
	private var widthFactorAlbum: CGFloat
	
	@Environment(ViewState.self) private var viewState
	@Environment(QueueInfo.self) private var queueInfo
	@State private var isOffline: Bool = false
	@State private var isFavorite: Bool? = nil
	
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
		
		if showArtist && showAlbum { // Both
			self.widthFactorTrack = 0.28
			self.widthFactorArtist = 0.28
			self.widthFactorAlbum = 0.28
		} else if showArtist != showAlbum { // One
			self.widthFactorTrack = 0.40
			self.widthFactorArtist = 0.40
			self.widthFactorAlbum = 0.40
		} else { // None
			self.widthFactorTrack = 0.66
			self.widthFactorArtist = 0.0
			self.widthFactorAlbum = 0.0
		}
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
									.foregroundColor(.black)
									.frame(width: 30, height: 30)
									.cornerRadius(CORNERRADIUS)
							}
						} else {
							Text("\(trackNumber ?? track.trackNumber)")
								.fontWeight(.thin)
								.foregroundColor(.secondary)
						}
						Text(track.title)
						if let version = track.version {
							Text(version)
								.foregroundColor(.secondary)
								.padding(.leading, -5)
								.layoutPriority(-1)
						}
						track.attributeHStack
							.padding(.leading, -5)
							.layoutPriority(1)
						Spacer(minLength: 5)
					}
					.frame(width: metrics.size.width * widthFactorTrack)
					.help(trackToolTipString)
					if showArtist {
						HStack {
							Text(track.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widthFactorArtist)
						.help(track.artists.formArtistString())
					}
					if showAlbum {
						HStack {
							Text(track.album.title)
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widthFactorAlbum)
						.help(track.album.title)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: track.duration))
					Spacer()
					if isOffline {
						Image(systemName: "cloud.fill")
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
						if isFavorite ?? false {
							print("Remove from Favorites")
							Task {
								if await session.favorites?.removeTrack(trackId: track.id) == true {
									session.helpers.offline.asyncSyncFavoriteTracks()
									isFavorite = false
									viewState.refreshCurrentView()
								}
							}
						} else {
							print("Add to Favorites")
							Task {
								if await session.favorites?.addTrack(trackId: track.id) == true {
									session.helpers.offline.asyncSyncFavoriteTracks()
									isFavorite = true
									viewState.refreshCurrentView()
								}
							}
						}
					} label: {
						Image(systemName: isFavorite ?? false ? "heart.fill" : "heart")
							.accessibilityLabel("Favorite")
							.accessibilityAddTraits(isFavorite ?? false ? .isSelected : [])
					}
					.buttonStyle(.plain)
				}
			}
		.foregroundColor(track.isUnavailable ? .secondary : .primary)
		.task(id: track.id) {
			isOffline = await track.isOffline(session: session)
			isFavorite = await track.isInFavorites(session: session)
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
