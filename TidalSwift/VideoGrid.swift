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
import SwiftUIExtensions

struct VideoGrid: View {
	let videos: [Video]
	let showArtists: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(videos) { video in
			VideoGridItem(video: video, showArtist: self.showArtists, session: self.session, player: self.player)
		}
		.gridStyle(
			ModularGridStyle(columns: .min(165), rows: .fixed(210), spacing: 5, padding: .init(top: 0, leading: 5, bottom: 5, trailing: 5))
		)
	}
}

struct VideoGridItem: View {
	let video: Video
	let showArtist: Bool
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		VStack {
			if video.getImageUrl(session: session, resolution: 320) != nil {
				URLImageSourceView(
					video.getImageUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(video.title)
				)
					.aspectRatio(contentMode: .fit)
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
					Text(video.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			HStack {
				Text(video.title)
					.lineLimit(1)
				if video.explicit {
					Text("􀂝")
						.foregroundColor(.secondary)
						.layoutPriority(1)
				}
			}
			.frame(width: 160)
			if showArtist {
				Text(video.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("Play Video: \(self.video.title)")
			guard let url = self.video.getVideoUrl(session: self.session) else {
				return
			}
			print(url)
			self.player.pause()
			let controller = VideoPlayerController(videoUrl: url, volume: self.playbackInfo.volume)
			controller.window?.title = "\(self.video.title) - \(self.video.artists.formArtistString())"
			controller.showWindow(nil)
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
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@State var t: Bool = false
	
	var body: some View {
		Group {
			if video.streamReady {
				Button(action: {
					print("Play Video: \(self.video.title)")
					guard let url = self.video.getVideoUrl(session: self.session) else {
						return
					}
					print(url)
					self.player.pause()
					let controller = VideoPlayerController(videoUrl: url, volume: self.playbackInfo.volume)
					controller.window?.title = "\(self.video.title) - \(self.video.artists.formArtistString())"
					controller.showWindow(nil)
				}) {
					Text("Play")
				}
			} else {
				Text("Video not available")
					.italic()
			}
			Divider()
			if video.artists[0].name != "Various Artists" {
				Group {
					ForEach(self.video.artists) { artist in
						Button(action: {
							self.viewState.push(artist: artist)
						}) {
							Text("Go to \(artist.name)")
						}
					}
				}
				Divider()
			}
			Group {
				if t || !t {
					if video.isInFavorites(session: session) ?? true {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeVideo(videoId: self.video.id)
							self.viewState.refreshCurrentView()
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
						print("Add \(self.video.title) to Playlist")
					}) {
						Text("Add to Playlist …")
					}
				}
				if video.streamReady {
					Divider()
					if video.getImageUrl(session: self.session, resolution: 1280) != nil {
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
				}
			}
		}
	}
}
