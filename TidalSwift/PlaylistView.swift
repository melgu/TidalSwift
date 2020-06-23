//
//  PlaylistView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct PlaylistView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	@State var t: Bool = false
	
	var isUserPlaylist: Bool {
		viewState.stack.last?.playlist?.creator.id == session.userId
	}
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if let tracks = viewState.stack.last?.tracks,
					   let playlist = viewState.stack.last?.playlist,
					   let imageUrlSmall = playlist.getImageUrl(session: session, resolution: 320),
					   let imageUrlBig = playlist.getImageUrl(session: session, resolution: 750) {
						ZStack(alignment: .bottomTrailing) {
							HStack {
								URLImageSourceView(
									imageUrlSmall,
									isAnimationEnabled: true,
									label: Text(playlist.title)
								)
								.aspectRatio(contentMode: .fill)
								.frame(width: 100, height: 100)
								.contentShape(Rectangle())
								.clipped()
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								.toolTip("Show image in new window")
								.onTapGesture {
									let controller = CoverWindowController(rootView:
																			URLImageSourceView(
																				imageUrlBig,
																				isAnimationEnabled: true,
																				label: Text(playlist.title)
																			)
									)
									controller.window?.title = playlist.title
									controller.showWindow(nil)
								}
								
								VStack(alignment: .leading) {
									HStack {
										Text(playlist.title)
											.font(.title)
											.lineLimit(2)
										if t || !t {
											if playlist.isInFavorites(session: session) ?? true {
												Image("heart.fill")
													.primaryIconColor()
													.onTapGesture {
														print("Remove from Favorites")
														session.favorites!.removePlaylist(playlistId: playlist.uuid)
														t.toggle()
													}
											} else {
												Image("heart")
													.primaryIconColor()
													.onTapGesture {
														print("Add to Favorites")
														session.favorites!.addPlaylist(playlistId: playlist.uuid)
														t.toggle()
													}
											}
										}
										Image("square.and.arrow.up")
											.primaryIconColor()
											.onTapGesture {
												Pasteboard.copy(string: playlist.url.absoluteString)
											}
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
							if t || !t {
								if playlist.isOffline(session: session) {
									Image("cloud.fill-big")
										.primaryIconColor()
										.onTapGesture {
											print("Remove from Offline")
											playlist.removeOffline(session: session)
											viewState.refreshCurrentView()
											t.toggle()
										}
								} else {
									Image("cloud-big")
										.primaryIconColor()
										.onTapGesture {
											print("Add to Offline")
											t.toggle()
											DispatchQueue.global(qos: .background).async {
												playlist.addOffline(session: session)
												DispatchQueue.main.async {
													viewState.refreshCurrentView()
													t.toggle()
												}
											}
										}
								}
							}
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(wrappedTracks: tracks.wrapped(), showCover: true, showAlbumTrackNumber: false,
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
	}
}
