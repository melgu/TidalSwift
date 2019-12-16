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
		viewState.stack.last!.playlist!.creator.id == session.userId
	}
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if viewState.stack.last?.tracks != nil {
						ZStack(alignment: .bottomTrailing) {
							HStack {
								URLImageSourceView(
									viewState.stack.last!.playlist!.getImageUrl(session: session, resolution: 320)!,
									isAnimationEnabled: true,
									label: Text(viewState.stack.last!.playlist!.title)
								)
									.aspectRatio(contentMode: .fill)
									.frame(width: 100, height: 100)
									.contentShape(Rectangle())
									.clipped()
									.cornerRadius(CORNERRADIUS)
									.shadow(radius: SHADOWRADIUS, y: SHADOWY)
									.onTapGesture {
										let controller = CoverWindowController(rootView:
											URLImageSourceView(
												self.viewState.stack.last!.playlist!.getImageUrl(session: self.session, resolution: 750)!,
												isAnimationEnabled: true,
												label: Text(self.viewState.stack.last!.playlist!.title)
											)
										)
										controller.window?.title = self.viewState.stack.last!.playlist!.title
										controller.showWindow(nil)
								}
								
								VStack(alignment: .leading) {
									HStack {
										Text(viewState.stack.last!.playlist!.title)
											.font(.title)
											.lineLimit(2)
										if t || !t {
											if viewState.stack.last!.playlist!.isInFavorites(session: session)! {
												Image("heart.fill")
													.secondaryIconColor()
													.onTapGesture {
														print("Remove from Favorites")
														self.session.favorites!.removePlaylist(playlistId: self.viewState.stack.last!.playlist!.uuid)
														self.t.toggle()
												}
											} else {
												Image("heart")
													.secondaryIconColor()
													.onTapGesture {
														print("Add to Favorites")
														self.session.favorites!.addPlaylist(playlistId: self.viewState.stack.last!.playlist!.uuid)
														self.t.toggle()
												}
											}
										}
										Image("square.and.arrow.up")
											.secondaryIconColor()
											.onTapGesture {
												Pasteboard.copy(string: self.viewState.stack.last!.playlist!.url.absoluteString)
										}
									}
									Text(viewState.stack.last!.playlist!.description ?? "")
									Text(viewState.stack.last!.playlist!.creator.name ?? "")
									Text("Created: \(DateFormatter.dateOnly.string(from: viewState.stack.last!.playlist!.created))")
										.foregroundColor(.secondary)
									Text("Last updated: \(DateFormatter.dateOnly.string(from: viewState.stack.last!.playlist!.lastUpdated))")
										.foregroundColor(.secondary)
								}
								Spacer(minLength: 5)
									.layoutPriority(-1)
								VStack(alignment: .leading) {
									Text("\(viewState.stack.last!.playlist!.numberOfTracks) Tracks")
										.foregroundColor(.secondary)
									Text(secondsToHoursMinutesSecondsString(seconds: viewState.stack.last!.playlist!.duration))
										.foregroundColor(.secondary)
									Spacer()
								}
							}
							if t || !t {
								if viewState.stack.last!.playlist!.isOffline(session: session) {
									Image("cloud.fill-big")
										.primaryIconColor()
										.onTapGesture {
											print("Remove from Offline")
											self.viewState.stack.last!.playlist!.removeOffline(session: self.session)
											self.viewState.refreshCurrentView()
											self.t.toggle()
									}
								} else {
									Image("cloud-big")
										.primaryIconColor()
										.onTapGesture {
											print("Add to Offline")
											self.t.toggle()
											DispatchQueue.global(qos: .background).async {
												self.viewState.stack.last!.playlist!.addOffline(session: self.session)
												DispatchQueue.main.async {
													self.viewState.refreshCurrentView()
													self.t.toggle()
												}
											}
									}
								}
							}
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(wrappedTracks: viewState.stack.last!.tracks!.wrap(), showCover: true, showAlbumTrackNumber: false,
								  showArtist: true, showAlbum: true, playlist: isUserPlaylist ? viewState.stack.last!.playlist : nil,
								  session: session, player: player)
					}
					
					Spacer(minLength: 0)
				}
				.padding(.top, 40)
			}
			BackButton()
		}
	}
}
