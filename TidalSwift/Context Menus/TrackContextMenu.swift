//
//  TrackContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct TrackContextMenu: View {
	let track: Track
	let indexInPlaylist: Int? // This having a value implies TrackList is User Playlist
	let playlist: Playlist?
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
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
					Button {
						player.add(track: track, .now)
					} label: {
						Text("Add Now")
					}
					Button {
						player.add(track: track, .next)
					} label: {
						Text("Add Next")
					}
					Button {
						player.add(track: track, .last)
					} label: {
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
						Button {
							viewState.push(artist: artist)
						} label: {
							Text("Go to \(artist.name)")
						}
					}
					Divider()
				}
				Button {
					viewState.push(album: track.album)
				} label: {
					Text("Go to Album")
				}
			}
			Divider()
			Group {
					if track.isInFavorites(session: session) ?? false {
						Button {
							print("Remove from Favorites")
							session.favorites?.removeTrack(trackId: track.id)
							session.helpers.offline.asyncSyncFavoriteTracks()
							viewState.refreshCurrentView()
						} label: {
							Text("Remove from Favorites")
						}
					} else {
						Button {
							print("Add to Favorites")
							session.favorites?.addTrack(trackId: track.id)
							session.helpers.offline.asyncSyncFavoriteTracks()
							viewState.refreshCurrentView()
						} label: {
							Text("Add to Favorites")
						}
					}
				if track.streamReady {
					Button {
						print("Add \(track.title) to Playlist")
						playlistEditingValues.tracks = [track]
						playlistEditingValues.showAddTracksModal = true
					} label: {
						Text("Add to Playlist …")
					}
				}
				if indexInPlaylist != nil {
					Button {
						print("Remove \(track.title) from Playlist")
						playlistEditingValues.tracks = [track]
						playlistEditingValues.indexToRemove = indexInPlaylist
						playlistEditingValues.playlist = playlist
						playlistEditingValues.showRemoveTracksModal = true
					} label: {
						Text("Remove from Playlist …")
					}
				}
				Divider()
				if track.streamReady {
					Button {
						print("Download")
						DispatchQueue.global(qos: .background).async {
							_ = session.helpers.download.download(track: track, audioQuality: player.nextAudioQuality)
						}
					} label: {
						Text("Download")
					}
					Divider()
					Button {
						print("Radio")
						if let radioTracks = track.radio(session: session) {
							player.add(tracks: radioTracks, .now)
						}
					} label: {
						Text("Radio")
					}
					if let coverUrl = track.album.getCoverUrl(session: session, resolution: 1280) {
						Button {
							print("Cover")
							let title = "\(track.title) – \(track.album.title)"
							let controller = ImageWindowController(
								imageUrl: coverUrl,
								title: title
							)
							controller.window?.title = title
							controller.showWindow(nil)
						} label: {
							Text("Cover")
						}
					}
					Button {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(session: session, track: track)
								.environmentObject(viewState)
						)
						controller.window?.title = "Credits – \(track.title)"
						controller.showWindow(nil)
					} label: {
						Text("Credits")
					}
					Button {
						print("Share Track")
						Pasteboard.copy(string: track.url.absoluteString)
					} label: {
						Text("Copy URL")
					}
				}
			}
		}
	}
}
