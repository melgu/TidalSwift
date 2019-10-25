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
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 200, hSpacing: 5, vSpacing: 5)
		)
	}
}

struct PlaylistGridItem: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			if playlist.getImageUrl(session: session, resolution: 320) != nil {
				//				Rectangle()
				URLImageSourceView(
					playlist.getImageUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(playlist.title)
				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
			} else {
				ZStack {
					Rectangle()
						.frame(width: 160, height: 160)
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
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
			print("Second Click. \(self.playlist.title)")
			self.player.add(playlist: self.playlist, .now)
		}
		.onTapGesture(count: 1) {
			print("First Click. \(self.playlist.title)")
			self.viewState.push(playlist: self.playlist)
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
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@State var t: Bool = false
	
	var body: some View {
		Group {
//			Group{
				Button(action: {
					self.player.add(playlist: self.playlist, .now)
				}) {
					Text("Play Now")
				}
				Button(action: {
					self.player.add(playlist: self.playlist, .next)
				}) {
					Text("Play Next")
				}
				Button(action: {
					self.player.add(playlist: self.playlist, .last)
				}) {
					Text("Play Last")
				}
//			}
			Divider()
			Group {
				if playlist.creator.id == session.userId { // My playlist
					Button(action: {
						print("Edit Playlist")
						self.playlistEditingValues.playlistToModify = self.playlist
						self.playlistEditingValues.showEditModal = true
					}) {
						Text("Edit Playlist")
					}
					Button(action: {
						print("Delete Playlist")
						self.playlistEditingValues.playlistToModify = self.playlist
						self.playlistEditingValues.showDeleteModal = true
					}) {
						Text("Delete Playlist")
					}
				} else {
					if t || !t {
						if playlist.isInFavorites(session: session)! {
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
				}
				Button(action: {
					print("Add \(self.playlist.title) to Playlist")
					if let tracks = self.session.getPlaylistTracks(playlistId: self.playlist.uuid) {
						self.playlistEditingValues.tracksToAdd = tracks
						self.playlistEditingValues.showAddTracksModal = true
					}
				}) {
					Text("Add to Playlist …")
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
					print("Download")
					_ = self.session.helpers?.download(playlist: self.playlist)
				}) {
					Text("Download")
				}
//			}
			Divider()
			Group {
				if playlist.getImageUrl(session: self.session, resolution: 750) != nil {
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
}

//struct PlaylistGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistGrid()
//    }
//}
