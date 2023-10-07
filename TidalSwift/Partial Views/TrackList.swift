//
//  TrackList.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackList: View {
	let wrappedTracks: [WrappedTrack]
	let showCover: Bool
	let showAlbumTrackNumber: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let playlist: Playlist? // Has to be nil if not displaying User Playlist
	let session: Session
	let player: Player
	
	var body: some View {
		LazyVStack {
			ForEach(wrappedTracks) { wrappedTrack in
				TrackRow(track: wrappedTrack.track, showCover: showCover, showArtist: showArtist, showAlbum: showAlbum,
						 trackNumber: showAlbumTrackNumber ? nil : wrappedTrack.id, session: session)
				.onTapGesture(count: 2) {
					if wrappedTrack.track.isUnavailable { return }
					print("\(wrappedTrack.track.id) \(wrappedTrack.track.title)")
					player.add(tracks: wrappedTracks.unwrapped(), .now, playAt: wrappedTrack.id)
				}
				.contextMenu {
					TrackContextMenu(track: wrappedTrack.track, indexInPlaylist: playlist != nil ? wrappedTrack.id : nil, playlist: playlist, session: session, player: player)
				}
				Divider()
			}
		}
		.padding(.horizontal)
	}
}

struct TrackRow: View {
	let track: Track
	let showCover: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let trackNumber: Int?
	let session: Session
	
	var widthFactorTrack: CGFloat
	var widthFactorArtist: CGFloat
	var widthFactorAlbum: CGFloat
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var queueInfo: QueueInfo
	
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
							queueInfo.queue[queueInfo.currentIndex].track == track {
							Image("play.fill")
								.secondaryIconColor()
						}
						if showCover {
							if let coverUrl = track.getCoverUrl(session: session, resolution: 80) {
								URLImageSourceView(
									coverUrl,
									isAnimationEnabled: true,
									label: Text(track.title)
								)
								.frame(width: 30, height: 30)
								.cornerRadius(CORNERRADIUS)
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
					.toolTip(trackToolTipString)
					if showArtist {
						HStack {
							Text(track.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widthFactorArtist)
						.toolTip(track.artists.formArtistString())
					}
					if showAlbum {
						HStack {
							Text(track.album.title)
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * widthFactorAlbum)
						.toolTip(track.album.title)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: track.duration))
					Spacer()
					if track.isOffline(session: session) {
						Image("cloud.fill")
							.secondaryIconColor()
					}
					Image("c.circle")
						.primaryIconColor()
						.onTapGesture {
							let controller = ResizableWindowController(rootView:
								CreditsView(session: session, track: track)
								.environmentObject(viewState)
							)
							controller.window?.title = "Credits – \(track.title)"
							controller.showWindow(nil)
						}
					if track.isInFavorites(session: session) ?? false {
						Image("heart.fill")
							.primaryIconColor()
							.onTapGesture {
								print("Remove from Favorites")
								session.favorites?.removeTrack(trackId: track.id)
								session.helpers.offline.asyncSyncFavoriteTracks()
								viewState.refreshCurrentView()
							}
					} else {
						Image("heart")
							.primaryIconColor()
							.onTapGesture {
								print("Add to Favorites")
								session.favorites?.addTrack(trackId: track.id)
								session.helpers.offline.asyncSyncFavoriteTracks()
								viewState.refreshCurrentView()
							}
					}
				}
			}
			.foregroundColor(track.isUnavailable ? .secondary : .primary)
		}
		.lineLimit(1)
		.frame(height: showCover ? 30 : 16) // Values tested "by hand"
	}
	
	var trackToolTipString: String {
		var s = track.title
		if let version = track.version {
			s += " (\(version))"
		}
		s += " – \(track.artists.formArtistString())"
		return s
	}
}
