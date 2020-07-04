//
//  ArtistGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct ArtistGrid: View {
	let artists: [Artist]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(artists) { artist in
			ArtistGridItem(artist: artist, session: session, player: player)
		}
		.gridStyle(
			ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(200), spacing: 10)
		)
	}
}

struct ArtistGridItem: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			if let pictureUrl = artist.getPictureUrl(session: session, resolution: 320) {
				URLImageSourceView(
					pictureUrl,
					isAnimationEnabled: true,
					label: Text(artist.name)
				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
			} else {
				ZStack {
					Rectangle()
						.foregroundColor(.black)
						.frame(width: 160, height: 160)
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
					Text(artist.name)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(5)
						.frame(width: 160)
				}
			}
			Text(artist.name)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.toolTip(artist.name)
		.onTapGesture(count: 2) {
			print("\(artist.name)")
			player.add(artist: artist, .now)
			player.play()
		}
		.onTapGesture(count: 1) {
			print("First Click. \(artist.name)")
			viewState.push(artist: artist)
		}
		.contextMenu {
			ArtistContextMenu(artist: artist, session: session, player: player)
		}
	}
}

struct ArtistContextMenu: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
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
				if artist.isInFavorites(session: session) ?? true {
					Button {
						print("Remove from Favorites")
						session.favorites?.removeArtist(artistId: artist.id)
						viewState.refreshCurrentView()
					} label: {
						Text("Remove from Favorites")
					}
				} else {
					Button {
						print("Add to Favorites")
						session.favorites?.addArtist(artistId: artist.id)
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
				print("Download all Albums of \(artist.name)")
				DispatchQueue.global(qos: .background).async {
					_ = session.helpers.downloadAllAlbums(from: artist)
				}
			} label: {
				Text("Download all Albums")
			}
			Divider()
			Group {
				Button {
					print("Radio")
					if let radioTracks = artist.radio(session: session) {
						player.add(tracks: radioTracks, .now)
					}
				} label: {
					Text("Radio")
				}
				if let pictureUrl = artist.getPictureUrl(session: session, resolution: 750) {
					Button {
						print("Picture")
						let controller = CoverWindowController(rootView:
							URLImageSourceView(
								pictureUrl,
								isAnimationEnabled: true,
								label: Text(artist.name)
							)
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
	}
}
