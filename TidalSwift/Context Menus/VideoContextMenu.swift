//
//  VideoContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "VideoContextMenu")

struct VideoContextMenu: View {
	let video: Video
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	@Environment(PlaybackInfo.self) private var playbackInfo
	@State private var isFavorite: Bool? = nil
	
	private var isOffline: Bool {
		video.isOffline(session: session)
	}
	
	var body: some View {
		Group {
			if video.streamReady {
				Button {
					#if canImport(AppKit)
					Task {
						logger.debug("Play Video: \(video.title)")
						guard let url = await video.playbackUrl(session: session) else {
							return
						}
						logger.debug("\(url)")
						player.pause()
						let controller = VideoPlayerController(videoUrl: url, volume: playbackInfo.volume)
						controller.window?.title = "\(video.title) - \(video.artists.formArtistString())"
						controller.showWindow(nil)
					}
					#else
					logger.debug("Coming soon")
					#endif
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
							logger.debug("Remove from Favorites")
							if await session.favorites?.removeVideo(videoId: video.id) == true {
								isFavorite = false
								viewState.refreshCurrentView()
							}
						}
					} label: {
						Text("Remove from Favorites")
					}
				} else {
					Button {
						Task {
							logger.debug("Add to Favorites")
							if await session.favorites?.addVideo(videoId: video.id) == true {
								isFavorite = true
							}
						}
					} label: {
						Text("Add to Favorites")
					}
				}
				if video.streamReady {
					Button {
						logger.debug("Add \(video.title) to Playlist")
					} label: {
						Text("Add to Playlist …")
					}
					Divider()
					if isOffline {
						Button {
							logger.debug("Remove from Offline")
							video.removeOffline(session: session)
							viewState.refreshCurrentView()
						} label: {
							Text("Remove from Offline")
						}
					} else {
						Button {
							logger.debug("Add to Offline")
							video.addOffline(session: session)
						} label: {
							Text("Add to Offline")
						}
					}
					Button {
						Task {
							logger.debug("Download")
							_ = await session.helpers.download.download(video: video)
						}
					} label: {
						Text("Download")
					}
				}
				#if canImport(AppKit)
				if video.streamReady {
					Divider()
					if let imagegUrl = video.imageUrl(session: session, resolution: 1280) {
						Button {
							logger.debug("Preview Image")
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
				#endif
			}
		}
		.task(id: video.id) {
			isFavorite = await video.isInFavorites(session: session)
		}
	}
}
