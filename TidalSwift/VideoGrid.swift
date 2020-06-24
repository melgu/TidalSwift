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
			VideoGridItem(video: video, showArtist: showArtists, session: session, player: player)
		}
		.gridStyle(
			ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(210), spacing: 10)
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
			if let imageUrl = video.getImageUrl(session: session, resolution: 320) {
				URLImageSourceView(
					imageUrl,
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
		.toolTip("\(video.title) – \(video.artists.formArtistString())")
		.onTapGesture(count: 2) {
			print("Play Video: \(video.title)")
			guard let url = video.getVideoUrl(session: session) else {
				return
			}
			print(url)
			player.pause()
			let controller = VideoPlayerController(videoUrl: url, volume: playbackInfo.volume)
			controller.window?.title = "\(video.title) - \(video.artists.formArtistString())"
			controller.showWindow(nil)
		}
		.contextMenu {
			VideoContextMenu(video: video, session: session, player: player)
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
					print("Play Video: \(video.title)")
					guard let url = video.getVideoUrl(session: session) else {
						return
					}
					print(url)
					player.pause()
					let controller = VideoPlayerController(videoUrl: url, volume: playbackInfo.volume)
					controller.window?.title = "\(video.title) - \(video.artists.formArtistString())"
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
					ForEach(video.artists) { artist in
						Button(action: {
							viewState.push(artist: artist)
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
							session.favorites?.removeVideo(videoId: video.id)
							viewState.refreshCurrentView()
							t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							session.favorites?.addVideo(videoId: video.id)
							t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if video.streamReady {
					Button(action: {
						print("Add \(video.title) to Playlist")
					}) {
						Text("Add to Playlist …")
					}
				}
				if video.streamReady {
					Divider()
					if let imagegUrl = video.getImageUrl(session: session, resolution: 1280) {
						Button(action: {
							print("Preview Image")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									imagegUrl,
									isAnimationEnabled: true,
									label: Text(video.title)
								)
							)
							controller.window?.title = video.title
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
