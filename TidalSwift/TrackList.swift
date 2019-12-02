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
					self.player.add(tracks: self.wrappedTracks.unwrapped(), .now)
					self.player.play(atIndex: wrappedTrack.id)
			}
			.contextMenu {
				TrackContextMenu(track: wrappedTrack.track, indexInPlaylist: self.playlist != nil ? wrappedTrack.id : nil, playlist: self.playlist, session: self.session, player: self.player)
			}
			Divider()
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
							Text("􀊄")
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
						Text(self.track.attributeString)
							.padding(.leading, -5)
							.foregroundColor(.secondary)
							.layoutPriority(1)
						Spacer(minLength: 5)
					}
					.frame(width: metrics.size.width * self.widthFactorTrack)
					if self.showArtist {
						HStack {
							Text(self.track.artists.formArtistString())
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * self.widthFactorArtist)
					}
					if self.showAlbum {
						HStack {
							Text(self.track.album.title)
							Spacer(minLength: 5)
						}
						.frame(width: metrics.size.width * self.widthFactorAlbum)
					}
				}
				Group {
					Text(secondsToHoursMinutesSecondsString(seconds: self.track.duration))
					Spacer()
					if self.track.isOffline(session: self.session) ?? false {
						Text("􀇃")
							.foregroundColor(.secondary)
					}
					Text("􀅴")
						.onTapGesture {
							let controller = ResizableWindowController(rootView:
								CreditsView(session: self.session, track: self.track)
							)
							controller.window?.title = "Credits – \(self.track.title)"
							controller.showWindow(nil)
					}
					if self.t || !self.t {
						if self.track.isInFavorites(session: self.session) ?? false {
							Text("􀊵")
								.onTapGesture {
									print("Remove from Favorites")
									self.session.favorites!.removeTrack(trackId: self.track.id)
									self.session.helpers?.offline.syncFavoriteTracks()
									self.viewState.refreshCurrentView()
									self.t.toggle()
							}
						} else {
							Text("􀊴")
								.onTapGesture {
									print("Add to Favorites")
									self.session.favorites!.addTrack(trackId: self.track.id)
									self.session.helpers?.offline.syncFavoriteTracks()
									self.t.toggle()
							}
						}
					}
				}
			}
		}
			.padding()
			.frame(height: 30) // TODO: Is 40 no matter what when cover is shown. Why?
		
	}
}
