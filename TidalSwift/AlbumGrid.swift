//
//  AlbumGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct AlbumGrid: View {
	let albums: [Album]
	let showArtists: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(albums) { album in
			AlbumGridItem(album: album, showArtist: self.showArtists, session: self.session, player: self.player)
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 210, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct AlbumGridItem: View {
	let album: Album
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if album.getCoverUrl(session: session, resolution: 320) != nil {
//				Rectangle()
				URLImageSourceView(
					album.getCoverUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(album.title)
				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					if album.streamReady != nil && album.streamReady! {
						Text(album.title)
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.lineLimit(5)
							.frame(width: 160)
					} else {
						Text("Album not available")
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.frame(width: 160)
					}
				}
			}
			Text(album.title)
				.lineLimit(1)
				.frame(width: 160)
			if showArtist {
				if album.artists != nil {
					Text(album.artists!.formArtistString())
						.fontWeight(.light)
						.foregroundColor(Color.gray)
						.lineLimit(1)
						.frame(width: 160)
				} else if album.artist != nil {
					Text(album.artist!.name)
						.fontWeight(.light)
						.foregroundColor(Color.gray)
						.lineLimit(1)
						.frame(width: 160)
				} else {
					Text("Unknown Artist")
						.fontWeight(.light)
						.foregroundColor(Color.gray)
						.lineLimit(1)
						.frame(width: 160)
				}
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.album.title)")
			self.player.add(album: self.album, .now)
		}
		.contextMenu {
			AlbumContextMenu(album: self.album, session: session, player: player)
		}
	}
}

struct AlbumContextMenu: View {
	let album: Album
	let session: Session
	let player: Player
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
			if album.streamReady != nil && album.streamReady! {
				Button(action: {
					self.player.add(album: self.album, .now)
				}) {
					Text("Play Now")
				}
				Button(action: {
					self.player.add(album: self.album, .next)
				}) {
					Text("Play Next")
				}
				Button(action: {
					self.player.add(album: self.album, .last)
				}) {
					Text("Play Last")
				}
			} else {
				Text("Album not available")
					.italic()
			}
			Divider()
			if self.t || !self.t {
				if self.album.isInFavorites(session: session)! {
					Button(action: {
						print("Remove from Favorites")
						self.session.favorites!.removeAlbum(albumId: self.album.id)
						self.t.toggle()
					}) {
						Text("Remove from Favorites")
					}
				} else {
					Button(action: {
						print("Add to Favorites")
						self.session.favorites!.addAlbum(albumId: self.album.id)
						self.t.toggle()
					}) {
						Text("Add to Favorites")
					}
				}
			}
			if album.streamReady != nil && album.streamReady! {
				Button(action: {
					print("Add Playlist \(self.album.title) to Playlist …")
				}) {
					Text("Add to Playlist …")
				}
				Divider()
				if self.album.getCoverUrl(session: self.session, resolution: 1280) != nil {
					Button(action: {
						print("Cover")
						let controller = CoverWindowController(rootView:
							URLImageSourceView(
								self.album.getCoverUrl(session: self.session, resolution: 1280)!,
								isAnimationEnabled: true,
								label: Text(self.album.title)
							)
						)
						controller.window?.title = self.album.title
						controller.showWindow(nil)
					}) {
						Text("Cover")
					}
				}
				Button(action: {
					print("Credits")
					let controller = ResizableWindowController(rootView:
						CreditsView(album: self.album, session: self.session)
					)
					controller.window?.title = "Credits – \(self.album.title)"
					controller.showWindow(nil)
				}) {
					Text("Credits")
				}
				Button(action: {
					print("Share")
				}) {
					Text("Share")
				}
			}
		}
	}
}

//struct AlbumGrid_Previews: PreviewProvider {
//	static var previews: some View {
//		AlbumGrid()
//	}
//}
