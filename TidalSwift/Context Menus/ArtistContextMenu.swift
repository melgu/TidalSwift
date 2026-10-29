//
//  ArtistContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "ArtistContextMenu")

struct ArtistContextMenu: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	@State private var isFavorite: Bool? = nil
	
	var body: some View {
		Group {
			Button {
				player.add(artist: artist, .now)
			} label: {
				Text("Add Now")
			}
			Button {
				player.add(artist: artist, .next)
			} label: {
				Text("Add Next")
			}
			Button {
				player.add(artist: artist, .last)
			} label: {
				Text("Add Last")
			}
			Divider()
			Group {
				if isFavorite ?? true {
					Button {
						Task {
							logger.debug("Remove from Favorites")
							if await session.favorites?.removeArtist(artistId: artist.id) == true {
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
							if await session.favorites?.addArtist(artistId: artist.id) == true {
								isFavorite = true
							}
						}
					} label: {
						Text("Add to Favorites")
					}
				}
			}
			Divider()
			Button {
				logger.debug("Offline")
			} label: {
				Text("Offline")
			}
			Button {
				Task {
					logger.debug("Download all Albums of \(artist.name)")
					_ = await session.helpers.download.downloadAllAlbums(from: artist, options: session.downloadOptions)
				}
			} label: {
				Text("Download all Albums")
			}
			Divider()
			Group {
				Button {
					Task {
						logger.debug("Radio")
						if let radioTracks = await artist.radio(session: session) {
							player.add(tracks: radioTracks, .now)
						}
					}
				} label: {
					Text("Radio")
				}
				#if canImport(AppKit)
				if let pictureUrl = artist.pictureUrl(session: session, resolution: 750) {
					Button {
						logger.debug("Picture")
						let controller = ImageWindowController(
							imageUrl: pictureUrl,
							title: artist.name
						)
						controller.window?.title = artist.name
						controller.showWindow(nil)
					} label: {
						Text("Picture")
					}
				}
				Button {
					logger.debug("Bio")
					let controller = ResizableWindowControllerFactory.create(rootView:
						ArtistBioView(session: session, artist: artist)
							.environment(viewState)
					)
					controller.window?.title = "Bio – \(artist.name)"
					controller.showWindow(nil)
				} label: {
					Text("Bio")
				}
				#endif
				if let url = artist.url {
					Button {
						logger.debug("Share Artist")
						Pasteboard.copy(string: url.absoluteString)
					} label: {
						Text("Copy URL")
					}
				}
			}
		}
		.task(id: artist.id) {
			isFavorite = await artist.isInFavorites(session: session)
		}
	}
}
