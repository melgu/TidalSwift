//
//  TrackGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackGridItem: View {
	let track: Track
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if track.album.getCoverUrl(session: session, resolution: 320) != nil {
				URLImageSourceView(
					track.album.getCoverUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(track.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
			} else {
				ZStack {
					Rectangle()
						.frame(width: 160, height: 160)
					Text(track.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(5)
						.frame(width: 160)
				}
			}
			HStack {
				Text(track.title)
					.lineLimit(1)
				Text(track.attributeString)
					.padding(.leading, -5)
					.foregroundColor(.secondary)
					.layoutPriority(1)
			}
			.frame(width: 160)
			if showArtist {
				Text(track.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.track.title)")
			self.player.add(track: self.track, .now)
			self.player.play()
		}
		.contextMenu {
			TrackContextMenu(track: self.track, session: self.session, player: self.player)
		}
	}
}

struct TrackContextMenu: View {
	let track: Track
	let indexInPlaylist: Int? // This having a value implies TrackList is User Playlist
	let playlist: Playlist?
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@State var t: Bool = false
	
	init(track: Track, indexInPlaylist: Int? = nil, playlist: Playlist? = nil, session: Session, player: Player) {
		self.track = track
		self.session = session
		self.player = player
		self.indexInPlaylist = indexInPlaylist
		self.playlist = playlist
	}
	
	var body: some View {
		Group {
			Group {
				if track.streamReady {
					Button(action: {
						self.player.add(track: self.track, .now)
					}) {
						Text("Play Now")
					}
					Button(action: {
						self.player.add(track: self.track, .next)
					}) {
						Text("Play Next")
					}
					Button(action: {
						self.player.add(track: self.track, .last)
					}) {
						Text("Play Last")
					}
				} else {
					Text("Track not available")
						.italic()
				}
			}
			Divider()
			Group {
				if track.artists[0].name != "Various Artists" {
					ForEach(self.track.artists) { artist in
						Button(action: {
							self.viewState.push(artist: artist)
						}) {
							Text("Go to \(artist.name)")
						}
					}
					Divider()
				}
				Button(action: {
					self.viewState.push(album: self.track.album)
				}) {
					Text("Go to Album")
				}
			}
			Divider()
			Group {
				if t || !t {
					if track.isInFavorites(session: session) ?? false {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeTrack(trackId: self.track.id)
							self.viewState.refreshCurrentView()
							self.t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							self.session.favorites!.addTrack(trackId: self.track.id)
							self.viewState.refreshCurrentView()
							self.t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if track.streamReady {
					Button(action: {
						print("Add \(self.track.title) to Playlist")
						self.playlistEditingValues.tracks = [self.track]
						self.playlistEditingValues.showAddTracksModal = true
					}) {
						Text("Add to Playlist …")
					}
				}
				if indexInPlaylist != nil {
					Button(action: {
						print("Remove \(self.track.title) from Playlist")
						self.playlistEditingValues.tracks = [self.track]
						self.playlistEditingValues.indexToRemove = self.indexInPlaylist
						self.playlistEditingValues.playlist = self.playlist
						self.playlistEditingValues.showRemoveTracksModal = true
					}) {
						Text("Remove from Playlist …")
					}
				}
				Divider()
				if track.streamReady {
					Button(action: {
						print("Download")
						_ = self.session.helpers?.download(track: self.track)
					}) {
						Text("Download")
					}
					Divider()
					Button(action: {
						print("Radio")
						if let radioTracks = self.track.radio(session: self.session) {
							self.player.add(tracks: radioTracks, .now)
						}
					}) {
						Text("Radio")
					}
					if track.album.getCoverUrl(session: session, resolution: 1280) != nil {
						Button(action: {
							print("Cover")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									self.track.album.getCoverUrl(session: self.session, resolution: 1280)!,
									isAnimationEnabled: true,
									label: Text("\(self.track.title) – \(self.track.album.title)")
								)
							)
							controller.window?.title = "\(self.track.title) – \(self.track.album.title)"
							controller.showWindow(nil)
						}) {
							Text("Cover")
						}
					}
					Button(action: {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(session: self.session, track: self.track)
						)
						controller.window?.title = "Credits – \(self.track.title)"
						controller.showWindow(nil)
					}) {
						Text("Credits")
					}
					Button(action: {
						print("Share")
					}) {
						Text("Share")
					}
				}
			}
		}
	}
}

extension Track {
	var attributeString: String {
		var s = ""
		if self.explicit {
			s += "􀂝"
		}
		if self.audioQuality == .master {
			s += "􀂭"
		} else if self.audioModes?.contains(.sony360RealityAudio) ?? false {
			s += "􀑈"
		}
		return s
	}
}
