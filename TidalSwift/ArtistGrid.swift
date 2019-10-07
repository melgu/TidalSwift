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
			ArtistGridItem(artist: artist, session: self.session, player: self.player)
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 200, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct ArtistGridItem: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if artist.getPictureUrl(session: session, resolution: 320) != nil {
//				Rectangle()
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
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
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
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
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
//			Text("WIP: Play Artist Radio")
//				.italic()
			Divider()
			if self.t || !self.t {
				if self.artist.isInFavorites(session: session)! {
					Button(action: {
						print("Remove from Favorites")
						self.session.favorites!.removeArtist(artistId: self.artist.id)
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
			Divider()
			Button(action: {
				print("Radio")
				if let radioTracks = self.artist.radio(session: self.session) {
					self.player.add(tracks: radioTracks, .now)
				}
			}) {
				Text("Radio")
			}
			if self.artist.getPictureUrl(session: self.session, resolution: 750) != nil {
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
					ArtistBioView(artist: self.artist, session: self.session)
				)
				controller.window?.title = "Bio – \(self.artist.name)"
				controller.showWindow(nil)
			}) {
				Text("Bio")
			}
			Button(action: {
				print("Share")
			}) {
				Text("Share")
			}
		}
	}
}

//struct ArtistGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        ArtistGrid()
//    }
//}
