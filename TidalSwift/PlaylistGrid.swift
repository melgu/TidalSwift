//
//  PlaylistGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct PlaylistGrid: View {
	let playlists: [Playlist]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(playlists) { playlist in
			PlaylistGridItem(playlist: playlist, session: self.session, player: self.player)
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 200, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct PlaylistGridItem: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if playlist.getImageUrl(session: session, resolution: 320) != nil {
//				Rectangle()
				URLImageSourceView(
					playlist.getImageUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(playlist.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					Text(playlist.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			Text(playlist.title)
				.frame(width: 160)
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.playlist.title)")
			self.player.add(playlist: self.playlist, .now)
		}
		.contextMenu {
			PlaylistContextMenu(playlist: self.playlist, session: session, player: player)
		}
	}
}

struct PlaylistContextMenu: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
			Button(action: {
				self.player.add(playlist: self.playlist, .now)
			}) {
				Text("Play now")
			}
			Button(action: {
				self.player.add(playlist: self.playlist, .next)
			}) {
				Text("Play next")
			}
			Button(action: {
				self.player.add(playlist: self.playlist, .last)
			}) {
				Text("Play last")
			}
			Divider()
			if self.t || !self.t {
				if self.playlist.isInFavorites(session: session)! {
					Button(action: {
						print("Remove from Favorites")
						self.session.favorites!.removePlaylist(playlistId: self.playlist.uuid)
						self.t.toggle()
					}) {
						Text("Remove from Favorites")
					}
				} else {
					Button(action: {
						print("Add to Favorites")
						self.session.favorites!.removePlaylist(playlistId: self.playlist.uuid)
						self.t.toggle()
					}) {
						Text("Add to Favorites")
					}
				}
			}
			
			Button(action: {
				print("Add Playlist \(self.playlist.title) to Playlist …")
			}) {
				Text("Add to Playlist …")
			}
			Divider()
			if self.playlist.getImageUrl(session: self.session, resolution: 750) != nil {
				Button(action: {
					print("Image")
					let controller = CoverWindowController(rootView:
						URLImageSourceView(
							self.playlist.getImageUrl(session: self.session, resolution: 750)!,
							isAnimationEnabled: true,
							label: Text(self.playlist.title)
						)
					)
					controller.window?.title = self.playlist.title
					controller.showWindow(nil)
				}) {
					Text("Image")
				}
			}
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

//struct PlaylistGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistGrid()
//    }
//}
