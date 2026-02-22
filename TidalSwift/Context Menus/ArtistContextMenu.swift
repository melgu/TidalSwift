//
//  ArtistContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ArtistContextMenu: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
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
							print("Remove from Favorites")
							if await session.favorites?.removeArtist(artistId: artist.id) == true {
								await MainActor.run {
									isFavorite = false
									viewState.refreshCurrentView()
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
							if await session.favorites?.addArtist(artistId: artist.id) == true {
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
			Divider()
			Button {
				print("Offline")
			} label: {
				Text("Offline")
			}
			Button {
				Task {
					print("Download all Albums of \(artist.name)")
					_ = await session.helpers.download.downloadAllAlbums(from: artist)
				}
			} label: {
				Text("Download all Albums")
			}
			Divider()
			Group {
				Button {
					Task {
						print("Radio")
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
						print("Picture")
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
					print("Bio")
					let controller = ResizableWindowController(rootView:
						ArtistBioView(session: session, artist: artist)
							.environmentObject(viewState)
					)
					controller.window?.title = "Bio – \(artist.name)"
					controller.showWindow(nil)
				} label: {
					Text("Bio")
				}
				#endif
				if let url = artist.url {
					Button {
						print("Share Artist")
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
