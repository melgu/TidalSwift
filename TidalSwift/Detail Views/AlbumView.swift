//
//  AlbumView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AlbumView: View {
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	
	@State private var cloudPressed: Bool = false
	@State private var isFavorite: Bool? = nil
	@State private var isOffline: Bool = false
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if let album = viewState.stack.last?.album,
					   let tracks = viewState.stack.last?.tracks,
					   let coverUrlSmall = album.getCoverUrl(session: session, resolution: 320),
					   let coverUrlBig = album.getCoverUrl(session: session, resolution: 1280) {
						ZStack(alignment: .bottomTrailing) {
							HStack {
								let cover = AsyncImage(url: coverUrlSmall)
									.frame(width: 100, height: 100)
									.cornerRadius(CORNERRADIUS)
									.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								#if canImport(AppKit)
								Button {
									let controller = ImageWindowController(
										imageUrl: coverUrlBig,
										title: album.title
									)
									controller.window?.title = album.title
									controller.showWindow(nil)
								} label: {
									cover
										.accessibilityLabel("Show cover in new window")
										.help("Show cover in new window")
								}
								.buttonStyle(.plain)
								#else
								cover
									.accessibilityHidden(true)
								#endif
								
								VStack(alignment: .leading) {
									HStack {
										Text(album.title)
											.font(.title)
											.lineLimit(1)
											.help(album.title)
										if album.hasAttributes {
											album.attributeHStack
												.padding(.leading, -5)
										}
										#if canImport(AppKit)
										Button {
											let controller = ResizableWindowControllerFactory.create(rootView:
												CreditsView(session: session, album: album)
													.environment(viewState)
											)
											controller.window?.title = "Credits – \(album.title)"
											controller.showWindow(nil)
										} label: {
											Image(systemName: "c.circle")
												.accessibilityLabel("Credits")
												.help("Credits")
										}
										.buttonStyle(.plain)
										#endif
										Button {
											if isFavorite ?? true {
												Task {
													print("Remove from Favorites")
													if await session.favorites?.removeAlbum(albumId: album.id) == true {
														isFavorite = false
														viewState.refreshCurrentView()
													}
												}
											} else {
												Task {
													print("Add to Favorites")
													if await session.favorites?.addAlbum(albumId: album.id) == true {
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
										if let url = album.url {
											ShareLink(item: url, preview: SharePreview(album.title)) {
												Image(systemName: "square.and.arrow.up")
													.accessibilityLabel("Share")
													.help("Share")
											}
											.buttonStyle(.plain)
										}
									}
									Text(album.artists?.formArtistString() ?? "")
									if let releaseDate = album.releaseDate {
										Text(DateFormatter.dateOnly.string(from: releaseDate))
									}
								}
								Spacer(minLength: 5)
								VStack(alignment: .leading) {
									if let numberOfTracks = album.numberOfTracks {
										Text("\(numberOfTracks) Tracks")
											.foregroundColor(.secondary)
									}
									if let duration = album.duration {
										Text(secondsToHoursMinutesSecondsString(seconds: duration))
											.foregroundColor(.secondary)
									}
									Spacer()
								}
							}
							Group {
								if cloudPressed && !isOffline {
									Image(systemName: "cloud.fill")
										.resizable()
										.scaledToFit()
										.secondaryIconColor()
								} else {
									Button {
										if isOffline {
											Task {
												print("Remove from Offline")
												await album.removeOffline(session: session)
												cloudPressed = false
												isOffline = false
												viewState.refreshCurrentView()
											}
										} else {
											Task {
												print("Add to Offline")
												cloudPressed = true
												await album.addOffline(session: session)
												isOffline = true
												viewState.refreshCurrentView()
											}
										}
									} label: {
										Image(systemName: isOffline ? "cloud.fill" : "cloud")
											.resizable()
											.scaledToFit()
											.accessibilityLabel("Available Offline")
											.accessibilityAddTraits(isOffline ? .isSelected : [])
									}
									.buttonStyle(.plain)
								}
							}
							.frame(width: 30)
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(tracks: tracks, showCover: false, showAlbumTrackNumber: true,
								  showArtist: true, showAlbum: false, playlist: nil, session: session, player: player)
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
		.task(id: viewState.stack.last?.album?.id) {
			guard let album = viewState.stack.last?.album else { return }
			isFavorite = await album.isInFavorites(session: session)
			isOffline = await album.isOffline(session: session)
		}
	}
}
