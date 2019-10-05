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
	
	init(albums: [Album], showArtists: Bool = false, session: Session, player: Player) {
		self.albums = albums
		self.showArtists = showArtists
		self.session = session
		self.player = player
	}
	
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
	
	@State var t: Bool = false
	
	init(album: Album, showArtist: Bool = false, session: Session, player: Player) {
		self.album = album
		self.showArtist = showArtist
		self.session = session
		self.player = player
	}
	
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
			Button(action: {
				self.player.add(album: self.album, .next)
			}) {
				Text("Play next")
			}
			Button(action: {
				self.player.add(album: self.album, .last)
			}) {
				Text("Play last")
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
			
			Button(action: {
				print(" to Playlist …")
			}) {
				Text("Add to Playlist …")
			}
			Divider()
			Button(action: {
				print("Credits")
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

//struct AlbumGrid_Previews: PreviewProvider {
//	static var previews: some View {
//		AlbumGrid()
//	}
//}
