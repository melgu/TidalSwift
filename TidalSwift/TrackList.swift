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
		ForEach(wrappedTracks) { wrappedTrack in
			TrackRow(track: wrappedTrack.track, showCover: self.showCover, showArtist: self.showArtist, showAlbum: self.showAlbum,
					 trackNumber: self.showAlbumTrackNumber ? nil : wrappedTrack.id, session: self.session)
				.onTapGesture(count: 2) {
					print("\(wrappedTrack.track.title)")
					self.player.add(tracks: self.wrappedTracks.unwrapped(), .now, playAt: wrappedTrack.id)
					self.player.play(atIndex: wrappedTrack.id)
			}
			.contextMenu {
				TrackContextMenu(track: wrappedTrack.track, indexInPlaylist: self.playlist != nil ? wrappedTrack.id : nil, playlist: self.playlist, session: self.session, player: self.player)
			}
			Divider()
				.padding(.horizontal)
		}
	}
}

struct TrackRow: View {
	let track: Track
	let showCover: Bool
	let showArtist: Bool
	let showAlbum: Bool
	let trackNumber: Int?
	let session: Session
	
	var coverUrl: URL? = nil
	var widthFactorTrack: CGFloat
	var widthFactorArtist: CGFloat
	var widthFactorAlbum: CGFloat
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var queueInfo: QueueInfo
	@State var t: Bool = false
	
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
		
		if showCover {
			self.coverUrl = track.getCoverUrl(session: session, resolution: 80)
		}
		
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
						if !self.queueInfo.queue.isEmpty &&
							self.queueInfo.queue[self.queueInfo.currentIndex].track == self.track {
							Image("play.fill")
								.secondaryIconColor()
						}
						if self.showCover {
							if self.coverUrl != nil {
								URLImageSourceView(
									self.coverUrl!,
									isAnimationEnabled: true,
									label: Text(self.track.title)
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
							Text("\(self.trackNumber ?? self.track.trackNumber)")
								.fontWeight(.thin)
								.foregroundColor(.secondary)
						}
						Text(self.track.title)
						if self.track.version != nil {
							Text("(\(self.track.version!))")
								.foregroundColor(.secondary)
								.padding(.leading, -5)
								.layoutPriority(-1)
						}
						self.track.attributeHStack
							.padding(.leading, -5)
							.layoutPriority(1)
						Spacer(minLength: 5)
					}
					.frame(width: metrics.size.width * self.widthFactorTrack)
					.toolTip("\(self.track.title)\(self.track.version != nil ? " (\(self.track.version!))" : "")")
					if self.showArtist {
						HStack {
							Text(self.track.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * self.widthFactorArtist)
						.toolTip(self.track.artists.formArtistString())
					}
					if self.showAlbum {
						HStack {
							Text(self.track.album.title)
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * self.widthFactorAlbum)
						.toolTip(self.track.album.title)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: self.track.duration))
					Spacer()
					if self.track.isOffline(session: self.session) {
						Image("cloud.fill")
							.secondaryIconColor()
					}
					Image("info.circle")
						.primaryIconColor()
						.onTapGesture {
							let controller = ResizableWindowController(rootView:
								CreditsView(session: self.session, track: self.track)
									.environmentObject(self.viewState)
							)
							controller.window?.title = "Credits – \(self.track.title)"
							controller.showWindow(nil)
					}
					if self.t || !self.t {
						if self.track.isInFavorites(session: self.session) ?? false {
							Image("heart.fill")
								.primaryIconColor()
								.onTapGesture {
									print("Remove from Favorites")
									self.session.favorites!.removeTrack(trackId: self.track.id)
									self.session.helpers.offline.asyncSyncFavoriteTracks()
//									self.viewState.refreshCurrentView()
									self.t.toggle()
							}
						} else {
							Image("heart")
								.primaryIconColor()
								.onTapGesture {
									print("Add to Favorites")
									self.session.favorites!.addTrack(trackId: self.track.id)
									self.session.helpers.offline.asyncSyncFavoriteTracks()
//									self.viewState.refreshCurrentView()
									self.t.toggle()
							}
						}
					}
				}
			}
		}
		.lineLimit(1)
		.frame(height: showCover ? 30 : 16) // Values tested "by hand"
		.padding(.horizontal)
	}
}
