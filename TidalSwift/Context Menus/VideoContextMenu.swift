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
	@Environment(Offline.self) private var offline
	@Environment(FavoritesState.self) private var favoritesState
	
	private var isOffline: Bool {
		offline.isVideoOffline(video: video)
	}
	
	var body: some View {
		Group {
			if video.streamReady {
				Button {
					#if canImport(AppKit)
					Task {
						await player.play(video: video)
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
				if favoritesState.contains(video: video) {
					Button {
						Task {
							logger.debug("Remove from Favorites")
							if await favoritesState.removeVideo(videoId: video.id) {
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
							await favoritesState.addVideo(videoId: video.id)
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
							offline.remove(video: video)
							viewState.refreshCurrentView()
						} label: {
							Text("Remove from Offline")
						}
					} else {
						Button {
							logger.debug("Add to Offline")
							offline.add(video: video)
						} label: {
							Text("Add to Offline")
						}
					}
					Button {
						Task {
							logger.debug("Download")
							try? await session.helpers.download.download(video: video, options: offline.downloadOptions)
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
	}
}
