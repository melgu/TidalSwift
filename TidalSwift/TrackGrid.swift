//
//  TrackGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackGridItem: View {
	let track: Track
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if track.album.getCoverUrl(session: session, resolution: 320) != nil {
				//				Rectangle()
				URLImageSourceView(
					track.album.getCoverUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(track.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
			} else {
				ZStack {
					Rectangle()
						.frame(width: 160, height: 160)
					Text(track.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(5)
						.frame(width: 160)
				}
			}
			HStack {
				Text(track.title)
					.lineLimit(1)
				if track.explicit {
					Text("􀂝")
						.foregroundColor(.secondary)
						.layoutPriority(1)
				}
			}
			.frame(width: 160)
			if showArtist {
				Text(track.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.track.title)")
			self.player.add(track: self.track, .now)
		}
		.contextMenu {
			TrackContextMenu(track: self.track, session: self.session, player: self.player)
		}
	}
}

struct TrackContextMenu: View {
	let track: Track
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@State var t: Bool = false
	
	var body: some View {
		Group {
			Group {
				if track.streamReady {
					Button(action: {
						self.player.add(track: self.track, .now)
					}) {
						Text("Play Now")
					}
					Button(action: {
						self.player.add(track: self.track, .next)
					}) {
						Text("Play Next")
					}
					Button(action: {
						self.player.add(track: self.track, .last)
					}) {
						Text("Play Last")
					}
				} else {
					Text("Track not available")
						.italic()
				}
			}
			Divider()
			Group {
				if self.track.artists[0].name != "Various Artists" {
					ForEach(self.track.artists) { artist in
						Button(action: {
							self.viewState.artist = artist
							self.viewState.viewType = "SingleArtist"
						}) {
							Text("Go to \(artist.name)")
						}
					}
					Divider()
				}
				Button(action: {
					self.viewState.album = self.track.album
					self.viewState.viewType = "SingleAlbum"
				}) {
					Text("Go to Album")
				}
			}
			Divider()
			Group {
				if self.t || !self.t {
					if self.track.isInFavorites(session: session)! {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeTrack(trackId: self.track.id)
							self.t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							self.session.favorites!.addTrack(trackId: self.track.id)
							self.t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if track.streamReady {
					Button(action: {
						print("Add Playlist \(self.track.title) to Playlist …")
					}) {
						Text("Add to Playlist …")
					}
					Divider()
					Group {
						Button(action: {
							print("Offline")
						}) {
							Text("Offline")
						}
						Button(action: {
							print("Download")
							_ = self.session.helpers?.download(track: self.track)
						}) {
							Text("Download")
						}
					}
					Divider()
					Button(action: {
						print("Radio")
						if let radioTracks = self.track.radio(session: self.session) {
							self.player.add(tracks: radioTracks, .now)
						}
					}) {
						Text("Radio")
					}
					if self.track.album.getCoverUrl(session: self.session, resolution: 1280) != nil {
						Button(action: {
							print("Cover")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									self.track.album.getCoverUrl(session: self.session, resolution: 1280)!,
									isAnimationEnabled: true,
									label: Text("\(self.track.title) – \(self.track.album.title)")
								)
							)
							controller.window?.title = "\(self.track.title) – \(self.track.album.title)"
							controller.showWindow(nil)
						}) {
							Text("Cover")
						}
					}
					Button(action: {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(track: self.track, session: self.session)
						)
						controller.window?.title = "Credits – \(self.track.title)"
						controller.showWindow(nil)
					}) {
						Text("Credits")
					}
					Button(action: {
						print("Share")
					}) {
						Text("Share")
					}
				}
			}
		}
	}
}

//struct TrackGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackGrid()
//    }
//}
