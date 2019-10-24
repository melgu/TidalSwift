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
	let playlist: Playlist?
	let session: Session
	let player: Player
	
	let tracks: [Track]?
	
	@EnvironmentObject var viewState: ViewState
	@State var t: Bool = false
	
	init(playlist: Playlist?, session: Session, player: Player) {
		self.playlist = playlist
		self.session = session
		self.player = player
		
		if let playlist = playlist {
			self.tracks = session.getPlaylistTracks(playlistId: playlist.id)
		} else {
			self.tracks = nil
		}
	}
	
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
					Spacer()
				}
				if playlist == nil {
					HStack {
						Spacer()
					}
					Spacer()
				} else {
					HStack {
						URLImageSourceView(
							playlist!.getImageUrl(session: session, resolution: 320)!,
							isAnimationEnabled: true,
							label: Text(playlist!.title)
						)
							.frame(width: 100, height: 100)
							.onTapGesture {
								let controller = CoverWindowController(rootView:
									URLImageSourceView(
										self.playlist!.getImageUrl(session: self.session, resolution: 750)!,
										isAnimationEnabled: true,
										label: Text(self.playlist!.title)
									)
								)
								controller.window?.title = self.playlist!.title
								controller.showWindow(nil)
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(playlist!.title)
									.font(.title)
									.lineLimit(2)
//								Text("􀅴")
//									.foregroundColor(.secondary)
//									.onTapGesture {
//										// Nothing yet
//								}
								if t || !t {
									if playlist!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removePlaylist(playlistId: self.playlist!.uuid)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addPlaylist(playlistId: self.playlist!.uuid)
												self.t.toggle()
										}
									}
								}
								
							}
							Text(playlist!.creator.name ?? "")
							Text("Created: \(DateFormatter.dateOnly.string(from: playlist!.created))")
								.foregroundColor(.secondary)
							Text("Last updated: \(DateFormatter.dateOnly.string(from: playlist!.lastUpdated))")
								.foregroundColor(.secondary)
						}
						Spacer()
							.layoutPriority(-1)
						VStack(alignment: .leading) {
							Text("\(playlist!.numberOfTracks) Tracks")
								.foregroundColor(.secondary)
							Text(secondsToHoursMinutesSecondsString(seconds: playlist!.duration))
								.foregroundColor(.secondary)
							Spacer()
						}
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
					Divider()
					
					
					TrackList(tracks: tracks!, showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, session: session, player: player)
				}
			}
		}
	}
}

//struct PlaylistView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlaylistView()
//	}
//}
