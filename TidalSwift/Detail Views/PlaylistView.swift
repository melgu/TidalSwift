//
//  PlaylistView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct PlaylistView: View {
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	@State private var isFavorite: Bool? = nil
	@State private var isOffline: Bool = false
	
	private var isUserPlaylist: Bool {
		viewState.stack.last?.playlist?.creator.id == session.userId
	}
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if let tracks = viewState.stack.last?.tracks,
					   let playlist = viewState.stack.last?.playlist,
			   let imageUrlSmall = playlist.imageUrl(session: session, resolution: 320),
			   let imageUrlBig = playlist.imageUrl(session: session, resolution: 750) {
						ZStack(alignment: .bottomTrailing) {
							HStack {
								let image = AsyncImage(url: imageUrlSmall)
									.aspectRatio(contentMode: .fill)
									.frame(width: 100, height: 100)
									.contentShape(Rectangle())
									.clipped()
									.cornerRadius(CORNERRADIUS)
									.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								#if canImport(AppKit)
								Button {
									let controller = ImageWindowController(
										imageUrl: imageUrlBig,
										title: playlist.title
									)
									controller.window?.title = playlist.title
									controller.showWindow(nil)
								} label: {
									image
										.accessibilityLabel("Show image in new window")
										.help("Show image in new window")
								}
								.buttonStyle(.plain)
								#else
								image
									.accessibilityHidden(true)
								#endif
								
								VStack(alignment: .leading) {
									HStack {
										Text(playlist.title)
											.font(.title)
											.lineLimit(2)
										Button {
											if isFavorite ?? true {
												Task {
													print("Remove from Favorites")
													if await session.favorites?.removePlaylist(playlistId: playlist.uuid) == true {
														isFavorite = false
														viewState.refreshCurrentView()
													}
												}
											} else {
												Task {
													print("Add to Favorites")
													if await session.favorites?.addPlaylist(playlistId: playlist.uuid) == true {
														isFavorite = true
														viewState.refreshCurrentView()
													}
												}
											}
										} label: {
											Image(systemName: isFavorite ?? true ? "heart.fill" : "heart")
												.accessibilityLabel("Favorite")
												.accessibilityAddTraits(isFavorite ?? true ? .isSelected : [])
										}
										.buttonStyle(.plain)
										Button {
											Pasteboard.copy(string: playlist.url.absoluteString)
										} label: {
											Image(systemName: "square.and.arrow.up")
												.accessibilityLabel("Copy URL")
												.help("Copy URL")
										}
										.buttonStyle(.plain)
									}
									Text(playlist.description ?? "")
									Text(playlist.creator.name ?? "")
									Text("Created: \(DateFormatter.dateOnly.string(from: playlist.created))")
										.foregroundColor(.secondary)
									Text("Last updated: \(DateFormatter.dateOnly.string(from: playlist.lastUpdated))")
										.foregroundColor(.secondary)
								}
								Spacer(minLength: 5)
									.layoutPriority(-1)
								VStack(alignment: .leading) {
									Text("\(playlist.numberOfTracks) Tracks")
										.foregroundColor(.secondary)
									Text(secondsToHoursMinutesSecondsString(seconds: playlist.duration))
										.foregroundColor(.secondary)
									Spacer()
								}
							}
							Button {
								if isOffline {
									Task {
										print("Remove from Offline")
										await playlist.removeOffline(session: session)
										isOffline = false
										viewState.refreshCurrentView()
									}
								} else {
									Task {
										print("Add to Offline")
										await playlist.addOffline(session: session)
										isOffline = true
										viewState.refreshCurrentView()
									}
								}
							} label: {
								Image(systemName: isOffline ? "cloud.fill" : "cloud")
									.resizable()
									.scaledToFit()
									.frame(width: 30)
									.accessibilityLabel("Available Offline")
									.accessibilityAddTraits(isOffline ? .isSelected : [])
							}
							.buttonStyle(.plain)
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(tracks: tracks, showCover: true, showAlbumTrackNumber: false,
								  showArtist: true, showAlbum: true, playlist: isUserPlaylist ? playlist : nil,
								  session: session, player: player)
					} else {
						HStack {
							Spacer()
						}
					}
					
					Spacer(minLength: 0)
				}
				.padding(.top, 40)
			}
			BackButton()
		}
		.task(id: viewState.stack.last?.playlist?.uuid) {
			guard let playlist = viewState.stack.last?.playlist else { return }
			isFavorite = await playlist.isInFavorites(session: session)
			isOffline = await playlist.isOffline(session: session)
		}
	}
}
