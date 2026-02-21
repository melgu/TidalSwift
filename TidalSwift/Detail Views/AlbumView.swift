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
	
	@EnvironmentObject var viewState: ViewState
	
	@State var cloudPressed: Bool = false
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
								AsyncImage(url: coverUrlSmall) { image in
									image.resizable().scaledToFit()
								} placeholder: {
									Rectangle()
								}
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								.toolTip("Show cover in new window")
								.onTapGesture {
									let controller = ImageWindowController(
										imageUrl: coverUrlBig,
										title: album.title
									)
									controller.window?.title = album.title
									controller.showWindow(nil)
								}
								.accessibilityHidden(true)
								
								VStack(alignment: .leading) {
									HStack {
										Text(album.title)
											.font(.title)
											.lineLimit(1)
											.toolTip(album.title)
										if album.hasAttributes {
											album.attributeHStack
												.padding(.leading, -5)
										}
										Image(systemName: "c.circle")
											.toolTip("Credits")
											.onTapGesture {
												let controller = ResizableWindowController(rootView:
													CreditsView(session: session, album: album)
														.environmentObject(viewState)
												)
												controller.window?.title = "Credits – \(album.title)"
												controller.showWindow(nil)
											}
						if isFavorite ?? true {
							Image(systemName: "heart.fill")
								.onTapGesture {
									Task {
										print("Remove from Favorites")
										if await session.favorites?.removeAlbum(albumId: album.id) == true {
											await MainActor.run {
												isFavorite = false
												viewState.refreshCurrentView()
											}
										}
									}
								}
						} else {
							Image(systemName: "heart")
								.onTapGesture {
									Task {
										print("Add to Favorites")
										if await session.favorites?.addAlbum(albumId: album.id) == true {
											await MainActor.run {
												isFavorite = true
												viewState.refreshCurrentView()
											}
										}
									}
								}
						}
										if let url = album.url {
											Image(systemName: "square.and.arrow.up")
												.toolTip("Copy URL")
												.onTapGesture {
													Pasteboard.copy(string: url.absoluteString)
												}
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
					if isOffline {
						Image(systemName: "cloud.fill")
							.resizable()
							.scaledToFit()
							.onTapGesture {
								Task {
									print("Remove from Offline")
									await album.removeOffline(session: session)
									await MainActor.run {
										cloudPressed = false
										isOffline = false
										viewState.refreshCurrentView()
									}
								}
							}
					} else {
						if cloudPressed {
										Image(systemName: "cloud.fill")
											.resizable()
											.scaledToFit()
											.secondaryIconColor()
									} else {
							Image(systemName: "cloud")
								.resizable()
								.scaledToFit()
								.onTapGesture {
									Task {
										print("Add to Offline")
										await MainActor.run {
											cloudPressed = true
										}
										await album.addOffline(session: session)
										await MainActor.run {
											isOffline = true
											viewState.refreshCurrentView()
										}
									}
								}
						}
					}
							}
							.frame(width: 30)
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(wrappedTracks: tracks.wrapped(), showCover: false, showAlbumTrackNumber: true,
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
