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
	@State private var isFavorite: Bool? = nil
	@State private var isOffline: Bool = false
	
	var body: some View {
		Group {
			Group{
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
			}
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
					if isFavorite ?? false {
						Button {
							Task {
								print("Remove from Favorites")
								if await session.favorites?.removePlaylist(playlistId: playlist.uuid) == true {
									await MainActor.run {
										isFavorite = false
									}
								}
							}
						} label: {
							Text("Remove from Favorites")
						}
					} else {
						Button {
							Task {
								print("Add to Favorites")
								if await session.favorites?.addPlaylist(playlistId: playlist.uuid) == true {
									await MainActor.run {
										isFavorite = true
									}
								}
							}
						} label: {
							Text("Add to Favorites")
						}
					}
				}
				Button {
					Task {
						print("Add \(playlist.title) to Playlist")
						if let tracks = await session.playlistTracks(playlistId: playlist.uuid) {
							await MainActor.run {
								playlistEditingValues.tracks = tracks
								playlistEditingValues.showAddTracksModal = true
							}
						}
					}
				} label: {
					Text("Add to Playlist …")
				}
			}
			Divider()
			Group {
				if isOffline {
					Button {
						Task {
							print("Remove from Offline")
							await playlist.removeOffline(session: session)
							await MainActor.run {
								isOffline = false
								viewState.refreshCurrentView()
							}
						}
					} label: {
						Text("Remove from Offline")
					}
				} else {
					Button {
						Task {
							print("Add to Offline")
							await playlist.addOffline(session: session)
							await MainActor.run {
								isOffline = true
								viewState.refreshCurrentView()
							}
						}
					} label: {
						Text("Add to Offline")
					}
				}
				
				Button {
					Task {
						print("Download")
						_ = await session.helpers.download.download(playlist: playlist)
					}
				} label: {
					Text("Download")
				}
			}
			Divider()
			Group {
				#if canImport(AppKit)
				if let imageUrl = playlist.imageUrl(session: session, resolution: 750) {
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
				#endif
				Button {
					print("Share Playlist")
					Pasteboard.copy(string: playlist.url.absoluteString)
				} label: {
					Text("Copy URL")
				}
			}
		}
		.task(id: playlist.uuid) {
			isFavorite = await playlist.isInFavorites(session: session)
			isOffline = await playlist.isOffline(session: session)
		}
	}
}
