//
//  VideoGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct VideoGrid: View {
	let videos: [Video]
	let showArtists: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(videos) { video in
			VideoGridItem(video: video, showArtist: self.showArtists, session: self.session, player: self.player)
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 210, hSpacing: 5, vSpacing: 5)
		)
	}
}

struct VideoGridItem: View {
	let video: Video
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if video.getImageUrl(session: session, resolution: 320) != nil {
				//				Rectangle()
				URLImageSourceView(
					video.getImageUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(video.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					Text(video.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			Text(video.title)
				.lineLimit(1)
				.frame(width: 160)
			if showArtist {
				Text(video.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.gray)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.video.title)")
			//			self.player.add(playlist: self.playlist, .now)
		}
		.contextMenu {
			VideoContextMenu(video: self.video, session: self.session, player: self.player)
		}
	}
}

struct VideoContextMenu: View {
	let video: Video
	let session: Session
	let player: Player
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
			Group {
				if video.streamReady {
					Button(action: {
						print("Play Now")
					}) {
						Text("Play Now")
					}
					Button(action: {
						print("Play Next")
					}) {
						Text("Play Next")
					}
					Button(action: {
						print("Play Last")
					}) {
						Text("Play Last")
					}
				} else {
					Text("Video not available")
						.italic()
				}
			}
			Divider()
			Group {
				if self.t || !self.t {
					if self.video.isInFavorites(session: session)! {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeVideo(videoId: self.video.id)
							self.t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							self.session.favorites!.addVideo(videoId: self.video.id)
							self.t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if video.streamReady {
					Button(action: {
						print("Add Playlist \(self.video.title) to Playlist …")
					}) {
						Text("Add to Playlist …")
					}
					Divider()
					Button(action: {
						print("Offline")
					}) {
						Text("Offline")
					}
					Button(action: {
						print("Download")
//						let r = self.session.helpers?.download(video: self.video)
					}) {
						Text("Download")
					}
					Divider()
					if self.video.getImageUrl(session: self.session, resolution: 1280) != nil {
						Button(action: {
							print("Preview Image")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									self.video.getImageUrl(session: self.session, resolution: 1280)!,
									isAnimationEnabled: true,
									label: Text(self.video.title)
								)
							)
							controller.window?.title = self.video.title
							controller.showWindow(nil)
						}) {
							Text("Preview Image")
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
}

//struct VideoGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoGrid()
//    }
//}
