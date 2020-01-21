//
//  AlbumView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct AlbumView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	@State var t: Bool = false
	@State var cloudPressed: Bool = false
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if viewState.stack.last?.album != nil && viewState.stack.last?.tracks != nil {
						ZStack(alignment: .bottomTrailing) {
							HStack {
								URLImageSourceView(
									viewState.stack.last!.album!.getCoverUrl(session: session, resolution: 320)!,
									isAnimationEnabled: true,
									label: Text(viewState.stack.last!.album!.title)
								)
									.frame(width: 100, height: 100)
									.cornerRadius(CORNERRADIUS)
									.shadow(radius: SHADOWRADIUS, y: SHADOWY)
									.onTapGesture {
										let controller = CoverWindowController(rootView:
											URLImageSourceView(
												self.viewState.stack.last!.album!.getCoverUrl(session: self.session, resolution: 1280)!,
												isAnimationEnabled: true,
												label: Text(self.viewState.stack.last!.album!.title)
											)
										)
										controller.window?.title = self.viewState.stack.last!.album!.title
										controller.showWindow(nil)
								}
								
								VStack(alignment: .leading) {
									HStack {
										Text(viewState.stack.last!.album!.title)
											.font(.title)
											.lineLimit(2)
										viewState.stack.last!.album!.attributeHStack
											.padding(.leading, -5)
											.layoutPriority(1)
										Image("info.circle")
											.secondaryIconColor()
											.onTapGesture {
												let controller = ResizableWindowController(rootView:
													CreditsView(session: self.session, album: self.viewState.stack.last!.album!)
														.environmentObject(self.viewState)
												)
												controller.window?.title = "Credits – \(self.viewState.stack.last!.album!.title)"
												controller.showWindow(nil)
										}
										if t || !t {
											if viewState.stack.last!.album!.isInFavorites(session: session) ?? true {
												Image("heart.fill")
													.secondaryIconColor()
													.onTapGesture {
														print("Remove from Favorites")
														self.session.favorites!.removeAlbum(albumId: self.viewState.stack.last!.album!.id)
														self.t.toggle()
												}
											} else {
												Image("heart")
													.secondaryIconColor()
													.onTapGesture {
														print("Add to Favorites")
														self.session.favorites!.addAlbum(albumId: self.viewState.stack.last!.album!.id)
														self.t.toggle()
												}
											}
										}
										if viewState.stack.last!.album!.url != nil {
											Image("square.and.arrow.up")
												.secondaryIconColor()
												.onTapGesture {
													Pasteboard.copy(string: self.viewState.stack.last!.album!.url!.absoluteString)
											}
										}
									}
									Text(viewState.stack.last!.album!.artists?.formArtistString() ?? "")
									if viewState.stack.last!.album!.releaseDate != nil {
										Text(DateFormatter.dateOnly.string(from: viewState.stack.last!.album!.releaseDate!))
									}
								}
								Spacer(minLength: 5)
								VStack(alignment: .leading) {
									if viewState.stack.last!.album!.numberOfTracks != nil {
										Text("\(viewState.stack.last!.album!.numberOfTracks!) Tracks")
											.foregroundColor(.secondary)
									}
									if viewState.stack.last!.album!.duration != nil {
										Text(secondsToHoursMinutesSecondsString(seconds: viewState.stack.last!.album!.duration!))
											.foregroundColor(.secondary)
									}
									Spacer()
								}
							}
							Group {
								if t || !t {
									if viewState.stack.last!.album!.isOffline(session: session) {
										Image("cloud.fill-big")
											.primaryIconColor()
											.onTapGesture {
												print("Remove from Offline")
												self.cloudPressed = false
												self.viewState.stack.last!.album!.removeOffline(session: self.session)
												self.viewState.refreshCurrentView()
												self.t.toggle()
										}
									} else {
										if cloudPressed {
											Image("cloud.fill-big")
												.secondaryIconColor()
										} else {
											Image("cloud-big")
												.primaryIconColor()
												.onTapGesture {
													print("Add to Offline")
													self.cloudPressed = true
													self.viewState.stack.last!.album!.addOffline(session: self.session)
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
						
						TrackList(wrappedTracks: viewState.stack.last!.tracks!.wrapped(), showCover: false, showAlbumTrackNumber: true,
								  showArtist: true, showAlbum: false, playlist: nil,
								  session: session, player: player)
					} else {
						HStack {
							Text("Couldn't load Album \(viewState.stack.last?.album?.title ?? "").")
							Spacer()
						}
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
					}
					Spacer(minLength: 0)
				}
				.padding(.top, 40)
			}
			BackButton()
		}
	}
}
