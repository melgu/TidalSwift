//
//  PlaylistGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct PlaylistGrid: View {
	let playlists: [Playlist]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(playlists) { playlist in
			PlaylistGridItem(playlist: playlist, session: session, player: player)
		}
		.gridStyle(
			ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(200), spacing: 10)
		)
	}
}

struct PlaylistGridItem: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			ZStack(alignment: .bottomTrailing) {
				if let imageUrl = playlist.getImageUrl(session: session, resolution: 320) {
					URLImageSourceView(
						imageUrl,
						isAnimationEnabled: true,
						label: Text(playlist.title)
					)
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
						.contentShape(Rectangle())
						.clipped()
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				} else {
					ZStack {
						Rectangle()
							.foregroundColor(.black)
							.frame(width: 160, height: 160)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
						Text(playlist.title)
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.frame(width: 160)
					}
				}
				if playlist.isOffline(session: session) {
					Image("cloud.fill-big")
						.colorInvert()
						.shadow(radius: SHADOWRADIUS)
						.padding(5)
				}
			}
			Text(playlist.title)
				.frame(width: 160)
		}
		.padding(5)
		.toolTip(playlist.title)
		.onTapGesture(count: 2) {
			print("Second Click. \(playlist.title)")
			player.add(playlist: playlist, .now)
			player.play()
		}
		.onTapGesture(count: 1) {
			print("First Click. \(playlist.title)")
			viewState.push(playlist: playlist)
		}
		.contextMenu {
			PlaylistContextMenu(playlist: playlist, session: session, player: player)
		}
	}
}

struct PlaylistContextMenu: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
//			Group{
				Button {
					player.add(playlist: playlist, .now)
				} label: {
					Text("Play Now")
				}
				Button {
					player.add(playlist: playlist, .next)
				} label: {
					Text("Add Next")
				}
				Button {
					player.add(playlist: playlist, .last)
				} label: {
					Text("Add Last")
				}
//			}
			Divider()
			Group {
				if playlist.creator.id == session.userId { // My playlist
					Button {
						print("Edit Playlist")
						playlistEditingValues.playlist = playlist
						playlistEditingValues.showEditModal = true
					} label: {
						Text("Edit Playlist …")
					}
					Button {
						print("Delete Playlist")
						playlistEditingValues.playlist = playlist
						playlistEditingValues.showDeleteModal = true
					} label: {
						Text("Delete Playlist …")
					}
				} else {
					if t || !t {
						if playlist.isInFavorites(session: session) ?? false {
							Button {
								print("Remove from Favorites")
								session.favorites?.removePlaylist(playlistId: playlist.uuid)
								t.toggle()
							} label: {
								Text("Remove from Favorites")
							}
						} else {
							Button {
								print("Add to Favorites")
								session.favorites?.addPlaylist(playlistId: playlist.uuid)
								t.toggle()
							} label: {
								Text("Add to Favorites")
							}
						}
					}
				}
				Button {
					print("Add \(playlist.title) to Playlist")
					if let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) {
						playlistEditingValues.tracks = tracks
						playlistEditingValues.showAddTracksModal = true
					}
				} label: {
					Text("Add to Playlist …")
				}
			}
			Divider()
			Group {
				if t || !t {
					if playlist.isOffline(session: session) {
						Button {
							print("Remove from Offline")
							playlist.removeOffline(session: session)
							viewState.refreshCurrentView()
							t.toggle()
						} label: {
							Text("Remove from Offline")
						}
					} else {
						Button {
							print("Add to Offline")
							DispatchQueue.global(qos: .background).async {
								playlist.addOffline(session: session)
								DispatchQueue.main.async {
									viewState.refreshCurrentView()
									t.toggle()
								}
							}
						} label: {
							Text("Add to Offline")
						}
					}
				}
				
				Button {
					print("Download")
					DispatchQueue.global(qos: .background).async {
						_ = session.helpers.download(playlist: playlist)
					}
				} label: {
					Text("Download")
				}
			}
			Divider()
			Group {
				if let imageUrl = playlist.getImageUrl(session: session, resolution: 750) {
					Button {
						print("Image")
						let controller = CoverWindowController(rootView:
							URLImageSourceView(
								imageUrl,
								isAnimationEnabled: true,
								label: Text(playlist.title)
							)
						)
						controller.window?.title = playlist.title
						controller.showWindow(nil)
					} label: {
						Text("Image")
					}
				}
				Button {
					print("Share Playlist")
					Pasteboard.copy(string: playlist.url.absoluteString)
				} label: {
					Text("Copy URL")
				}
			}
		}
	}
}
