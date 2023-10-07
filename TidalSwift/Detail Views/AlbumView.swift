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
										if album.isInFavorites(session: session) ?? true {
											Image(systemName: "heart.fill")
												.onTapGesture {
													print("Remove from Favorites")
													session.favorites?.removeAlbum(albumId: album.id)
													viewState.refreshCurrentView()
												}
										} else {
											Image(systemName: "heart")
												.onTapGesture {
													print("Add to Favorites")
													session.favorites?.addAlbum(albumId: album.id)
													viewState.refreshCurrentView()
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
								if album.isOffline(session: session) {
									Image(systemName: "cloud.fill")
										.resizable()
										.scaledToFit()
										.onTapGesture {
											print("Remove from Offline")
											cloudPressed = false
											album.removeOffline(session: session)
											viewState.refreshCurrentView()
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
												print("Add to Offline")
												cloudPressed = true
												album.addOffline(session: session)
												viewState.refreshCurrentView()
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
	}
}
