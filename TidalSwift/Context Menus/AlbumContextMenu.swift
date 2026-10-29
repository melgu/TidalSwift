//
//  AlbumContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "AlbumContextMenu")

struct AlbumContextMenu: View {
	let album: Album
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	@Environment(PlaylistEditingValues.self) private var playlistEditingValues
	@Environment(Offline.self) private var offline
	@State private var isFavorite: Bool? = nil
	@State private var isOffline: Bool = false
	
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
				if isFavorite ?? false {
					Button {
						Task {
							logger.debug("Remove from Favorites")
							if await session.favorites?.removeAlbum(albumId: album.id) == true {
								isFavorite = false
								viewState.refreshCurrentView()
							}
						}
					} label: {
						Text("Remove from Favorites")
					}
				} else {
					Button {
						Task {
							logger.debug("Add to Favorites")
							if await session.favorites?.addAlbum(albumId: album.id) == true {
								isFavorite = true
							}
						}
					} label: {
						Text("Add to Favorites")
					}
				}
				if album.streamReady ?? false {
					Button {
						Task {
							logger.debug("Add \(album.title) to Playlist")
							if let tracks = await session.albumTracks(albumId: album.id) {
								playlistEditingValues.tracks = tracks
								playlistEditingValues.showAddTracksModal = true
							}
						}
					} label: {
						Text("Add to Playlist …")
					}
					Divider()
					Group {
						if isOffline {
							Button {
								Task {
									logger.debug("Remove from Offline")
									await offline.remove(album: album)
									isOffline = false
									viewState.refreshCurrentView()
								}
							} label: {
								Text("Remove from Offline")
							}
						} else {
							Button {
								Task {
									logger.debug("Add to Offline")
									await offline.add(album: album)
									isOffline = true
								}
							} label: {
								Text("Add to Offline")
							}
						}
						
						Button {
							Task {
								logger.debug("Download")
								_ = await session.helpers.download.download(album: album, options: offline.downloadOptions)
							}
						} label: {
							Text("Download")
						}
					}
					Divider()
					#if canImport(AppKit)
					if let coverUrl = album.getCoverUrl(session: session, resolution: 1280) {
						Button {
							logger.debug("Cover")
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
						logger.debug("Credits")
						let controller = ResizableWindowControllerFactory.create(rootView:
							CreditsView(session: session, album: album)
								.environment(viewState)
						)
						controller.window?.title = "Credits – \(album.title)"
						controller.showWindow(nil)
					} label: {
						Text("Credits")
					}
					#endif
					if let url = album.url {
						Button {
							logger.debug("Share")
							Pasteboard.copy(string: url.absoluteString)
						} label: {
							Text("Copy URL")
						}
					}
				}
			}
		}
		.task(id: album.id) {
			isFavorite = await album.isInFavorites(session: session)
			isOffline = await offline.isAlbumOffline(album: album)
		}
	}
}
