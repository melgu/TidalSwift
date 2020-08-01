//
//  AlbumContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AlbumContextMenu: View {
	let album: Album
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		Group {
			Group {
				if album.streamReady ?? false {
					Button {
						player.add(album: album, .now)
					} label: {
						Text("Add Now")
					}
					Button {
						player.add(album: album, .next)
					} label: {
						Text("Add Next")
					}
					Button {
						player.add(album: album, .last)
					} label: {
						Text("Add Last")
					}
				} else {
					Text("Album not available")
						.italic()
				}
			}
			Divider()
			if let artists = album.artists, artists[0].name != "Various Artists" {
				Group {
					ForEach(album.artists!) { artist in
						Button {
							viewState.push(artist: artist)
						} label: {
							Text("Go to \(artist.name)")
						}
					}
				}
				Divider()
			}
			Group {
				if album.isInFavorites(session: session) ?? false {
					Button {
						print("Remove from Favorites")
						session.favorites?.removeAlbum(albumId: album.id)
						viewState.refreshCurrentView()
					} label: {
						Text("Remove from Favorites")
					}
				} else {
					Button {
						print("Add to Favorites")
						session.favorites?.addAlbum(albumId: album.id)
					} label: {
						Text("Add to Favorites")
					}
				}
				if album.streamReady ?? false {
					Button {
						print("Add \(album.title) to Playlist")
						if let tracks = session.getAlbumTracks(albumId: album.id) {
							playlistEditingValues.tracks = tracks
							playlistEditingValues.showAddTracksModal = true
						}
					} label: {
						Text("Add to Playlist …")
					}
					Divider()
					Group {
						if album.isOffline(session: session) {
							Button {
								print("Remove from Offline")
								album.removeOffline(session: session)
								viewState.refreshCurrentView()
							} label: {
								Text("Remove from Offline")
							}
						} else {
							Button {
								print("Add to Offline")
								album.addOffline(session: session)
							} label: {
								Text("Add to Offline")
							}
						}
						
						Button {
							print("Download")
							DispatchQueue.global(qos: .background).async {
								_ = session.helpers.download(album: album)
							}
						} label: {
							Text("Download")
						}
					}
					Divider()
					if let coverUrl = album.getCoverUrl(session: session, resolution: 1280) {
						Button {
							print("Cover")
							let controller = ImageWindowController(
								imageUrl: coverUrl,
								title: album.title
							)
							controller.window?.title = album.title
							controller.showWindow(nil)
						} label: {
							Text("Cover")
						}
					}
					Button {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(session: session, album: album)
								.environmentObject(viewState)
						)
						controller.window?.title = "Credits – \(album.title)"
						controller.showWindow(nil)
					} label: {
						Text("Credits")
					}
					if let url = album.url {
						Button {
							print("Share")
							Pasteboard.copy(string: url.absoluteString)
						} label: {
							Text("Copy URL")
						}
					}
				}
			}
		}
	}
}
