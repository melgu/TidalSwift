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
import SwiftUIExtensions

struct ArtistGrid: View {
	let artists: [Artist]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(artists) { artist in
			ArtistGridItem(artist: artist, session: self.session, player: self.player)
		}
		.gridStyle(
			ModularGridStyle(columns: .min(165), rows: .fixed(200), spacing: 5, padding: .init(top: 0, leading: 5, bottom: 5, trailing: 5))
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
			if artist.getPictureUrl(session: session, resolution: 320) != nil {
				URLImageSourceView(
					artist.getPictureUrl(session: session, resolution: 320)!,
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
		.onTapGesture(count: 2) {
			print("\(self.artist.name)")
			self.player.add(artist: self.artist, .now)
			self.player.play()
		}
		.onTapGesture(count: 1) {
			print("First Click. \(self.artist.name)")
			self.viewState.push(artist: self.artist)
		}
		.contextMenu {
			ArtistContextMenu(artist: self.artist, session: self.session, player: self.player)
		}
	}
}

struct ArtistContextMenu: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
//			Group {
				Button(action: {
					self.player.add(artist: self.artist, .now)
				}) {
					Text("Play Now")
				}
				Button(action: {
					self.player.add(artist: self.artist, .next)
				}) {
					Text("Play Next")
				}
				Button(action: {
					self.player.add(artist: self.artist, .last)
				}) {
					Text("Play Last")
				}
//			}
			Divider()
			Group {
				if t || !t {
					if artist.isInFavorites(session: session) ?? true {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeArtist(artistId: self.artist.id)
							self.viewState.refreshCurrentView()
							self.t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							self.session.favorites!.addArtist(artistId: self.artist.id)
							self.t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
			}
			Divider()
//			Group {
				Button(action: {
					print("Offline")
				}) {
					Text("Offline")
				}
				Button(action: {
					print("Download all Albums of \(self.artist.name)")
					DispatchQueue.global(qos: .background).async {
						_ = self.session.helpers.downloadAllAlbums(from: self.artist)
					}
				}) {
					Text("Download all Albums")
				}
//			}
			Divider()
			Group {
				Button(action: {
					print("Radio")
					if let radioTracks = self.artist.radio(session: self.session) {
						self.player.add(tracks: radioTracks, .now)
					}
				}) {
					Text("Radio")
				}
				if artist.getPictureUrl(session: self.session, resolution: 750) != nil {
					Button(action: {
						print("Picture")
						let controller = CoverWindowController(rootView:
							URLImageSourceView(
								self.artist.getPictureUrl(session: self.session, resolution: 750)!,
								isAnimationEnabled: true,
								label: Text(self.artist.name)
							)
						)
						controller.window?.title = self.artist.name
						controller.showWindow(nil)
					}) {
						Text("Picture")
					}
				}
				Button(action: {
					print("Bio")
					let controller = ResizableWindowController(rootView:
						ArtistBioView(session: self.session, artist: self.artist)
							.environmentObject(self.viewState)
					)
					controller.window?.title = "Bio – \(self.artist.name)"
					controller.showWindow(nil)
				}) {
					Text("Bio")
				}
				if artist.url != nil {
					Button(action: {
						print("Share Artist")
						Pasteboard.copy(string: self.artist.url!.absoluteString)
					}) {
						Text("Share")
					}
				}
			}
		}
	}
}
