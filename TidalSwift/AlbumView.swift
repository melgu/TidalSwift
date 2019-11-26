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
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Button(action: {
						print("Back")
						self.viewState.pop()
					}) {
						Text("􀆉")
					}
					.padding(.leading, 10)
					Spacer(minLength: 0)
					LoadingSpinner()
				}
				if viewState.stack.last!.album != nil && viewState.stack.last!.tracks != nil {
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
								Text(viewState.stack.last!.album!.attributeString)
									.padding(.leading, -5)
									.foregroundColor(.secondary)
									.layoutPriority(1)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											CreditsView(session: self.session, album: self.viewState.stack.last!.album!)
										)
										controller.window?.title = "Credits – \(self.viewState.stack.last!.album!.title)"
										controller.showWindow(nil)
								}
								if t || !t {
									if viewState.stack.last!.album!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeAlbum(albumId: self.viewState.stack.last!.album!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addAlbum(albumId: self.viewState.stack.last!.album!.id)
												self.t.toggle()
										}
									}
								}
							}
							Text(viewState.stack.last!.album!.artists?.formArtistString() ?? "")
							if viewState.stack.last!.album!.releaseDate != nil {
								Text(DateFormatter.dateOnly.string(from: viewState.stack.last!.album!.releaseDate!))
							}
						}
						Spacer()
							.layoutPriority(-1)
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
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
					Divider()
					
					TrackList(tracks: viewState.stack.last!.tracks!, showCover: false, showAlbumTrackNumber: true,
							  showArtist: true, showAlbum: false, playlist: nil,
							  session: session, player: player)
					
					Spacer(minLength: 0)
				}
			}
		}
	}
}
