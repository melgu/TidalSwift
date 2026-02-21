//
//  VideoContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct VideoContextMenu: View {
	let video: Video
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@State private var isFavorite: Bool? = nil
	
	var body: some View {
		Group {
			if video.streamReady {
				Button {
					Task {
						print("Play Video: \(video.title)")
						guard let url = await video.videoUrl(session: session) else {
							return
						}
						print(url)
						player.pause()
						let controller = VideoPlayerController(videoUrl: url, volume: playbackInfo.volume)
						controller.window?.title = "\(video.title) - \(video.artists.formArtistString())"
						controller.showWindow(nil)
					}
				} label: {
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
						Button {
							viewState.push(artist: artist)
						} label: {
							Text("Go to \(artist.name)")
						}
					}
				}
				Divider()
			}
			Group {
				if isFavorite ?? true {
					Button {
						Task {
							print("Remove from Favorites")
							if await session.favorites?.removeVideo(videoId: video.id) == true {
								await MainActor.run {
									isFavorite = false
									viewState.refreshCurrentView()
								}
							}
						}
					} label: {
						Text("Remove from Favorites")
					}
				} else {
					Button {
						Task {
							print("Add to Favorites")
							if await session.favorites?.addVideo(videoId: video.id) == true {
								await MainActor.run {
									isFavorite = true
								}
							}
						}
					} label: {
						Text("Add to Favorites")
					}
				}
				if video.streamReady {
					Button {
						print("Add \(video.title) to Playlist")
					} label: {
						Text("Add to Playlist …")
					}
				}
				if video.streamReady {
					Divider()
					if let imagegUrl = video.imageUrl(session: session, resolution: 1280) {
						Button {
							print("Preview Image")
							let controller = ImageWindowController(
								imageUrl: imagegUrl,
								title: video.title
							)
							controller.window?.title = video.title
							controller.showWindow(nil)
						} label: {
							Text("Preview Image")
						}
					}
				}
			}
		}
		.task(id: video.id) {
			isFavorite = await video.isInFavorites(session: session)
		}
	}
}
