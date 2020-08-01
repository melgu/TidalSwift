//
//  PlaylistContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct PlaylistContextMenu: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		Group {
//			Group{
				Button {
					player.add(playlist: playlist, .now)
				} label: {
					Text("Add Now")
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
					if playlist.isInFavorites(session: session) ?? false {
						Button {
							print("Remove from Favorites")
							session.favorites?.removePlaylist(playlistId: playlist.uuid)
						} label: {
							Text("Remove from Favorites")
						}
					} else {
						Button {
							print("Add to Favorites")
							session.favorites?.addPlaylist(playlistId: playlist.uuid)
						} label: {
							Text("Add to Favorites")
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
				if playlist.isOffline(session: session) {
					Button {
						print("Remove from Offline")
						playlist.removeOffline(session: session)
						viewState.refreshCurrentView()
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
							}
						}
					} label: {
						Text("Add to Offline")
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
						let controller = ImageWindowController(
							imageUrl: imageUrl,
							title: playlist.title
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
