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
			if let coverUrl = track.album.getCoverUrl(session: session, resolution: 320) {
				URLImageSourceView(
					coverUrl,
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
				if let version = track.version {
					Text(version)
						.foregroundColor(.secondary)
						.padding(.leading, -5)
				}
				track.attributeHStack
					.padding(.leading, -5)
					.layoutPriority(1)
			}
			.lineLimit(1)
			.frame(width: 160)
			if showArtist {
				Text(track.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
					.padding(.top, track.hasAttributes ? -6.5 : 0)
			}
		}
		.padding(5)
		.toolTip(toolTipString)
		.onTapGesture(count: 2) {
			print("\(track.title)")
			player.add(track: track, .now)
			player.play()
		}
		.contextMenu {
			TrackContextMenu(track: track, session: session, player: player)
		}
	}
	
	var toolTipString: String {
		var s = track.title
		if let version = track.version {
			s += " (\(version))"
		}
		s += track.artists.formArtistString()
		return s
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
						player.add(track: track, .now)
					}) {
						Text("Play Now")
					}
					Button(action: {
						player.add(track: track, .next)
					}) {
						Text("Add Next")
					}
					Button(action: {
						player.add(track: track, .last)
					}) {
						Text("Add Last")
					}
				} else {
					Text("Track not available")
						.italic()
				}
			}
			Divider()
			Group {
				if track.artists[0].name != "Various Artists" {
					ForEach(track.artists) { artist in
						Button(action: {
							viewState.push(artist: artist)
						}) {
							Text("Go to \(artist.name)")
						}
					}
					Divider()
				}
				Button(action: {
					viewState.push(album: track.album)
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
							session.favorites?.removeTrack(trackId: track.id)
							session.helpers.offline.asyncSyncFavoriteTracks()
							viewState.refreshCurrentView()
							t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							session.favorites?.addTrack(trackId: track.id)
							session.helpers.offline.asyncSyncFavoriteTracks()
							viewState.refreshCurrentView()
							t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if track.streamReady {
					Button(action: {
						print("Add \(track.title) to Playlist")
						playlistEditingValues.tracks = [track]
						playlistEditingValues.showAddTracksModal = true
					}) {
						Text("Add to Playlist …")
					}
				}
				if indexInPlaylist != nil {
					Button(action: {
						print("Remove \(track.title) from Playlist")
						playlistEditingValues.tracks = [track]
						playlistEditingValues.indexToRemove = indexInPlaylist
						playlistEditingValues.playlist = playlist
						playlistEditingValues.showRemoveTracksModal = true
					}) {
						Text("Remove from Playlist …")
					}
				}
				Divider()
				if track.streamReady {
					Button(action: {
						print("Download")
						DispatchQueue.global(qos: .background).async {
							_ = session.helpers.download(track: track)
						}
					}) {
						Text("Download")
					}
					Divider()
					Button(action: {
						print("Radio")
						if let radioTracks = track.radio(session: session) {
							player.add(tracks: radioTracks, .now)
						}
					}) {
						Text("Radio")
					}
					if let coverUrl = track.album.getCoverUrl(session: session, resolution: 1280) {
						Button(action: {
							print("Cover")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									coverUrl,
									isAnimationEnabled: true,
									label: Text("\(track.title) – \(track.album.title)")
								)
							)
							controller.window?.title = "\(track.title) – \(track.album.title)"
							controller.showWindow(nil)
						}) {
							Text("Cover")
						}
					}
					Button(action: {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(session: session, track: track)
								.environmentObject(viewState)
						)
						controller.window?.title = "Credits – \(track.title)"
						controller.showWindow(nil)
					}) {
						Text("Credits")
					}
					Button(action: {
						print("Share Track")
						Pasteboard.copy(string: track.url.absoluteString)
					}) {
						Text("Copy URL")
					}
				}
			}
		}
	}
}

extension Track {
	var attributeHStack: some View {
		HStack {
			if explicit {
				Image("e.square")
			}
			if audioQuality == .master {
				Image("m.square.fill")
			} else if audioModes?.contains(.sony360RealityAudio) ?? false {
				Image("headphones")
			} else if audioModes?.contains(.dolbyAtmos) ?? false {
				Image("hifispeaker.fill")
			}
		}
		.secondaryIconColor()
	}
	
	var hasAttributes: Bool {
		explicit ||
			audioQuality == .master ||
			audioModes?.contains(.sony360RealityAudio) ?? false ||
			audioModes?.contains(.dolbyAtmos) ?? false
	}
	
	var isUnavailable: Bool {
		audioModes?.contains(.sony360RealityAudio) ?? false ||
			audioModes?.contains(.dolbyAtmos) ?? false
	}
}
