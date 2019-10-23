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
	let album: Album?
	let session: Session
	let player: Player
	
	let tracks: [Track]?
	
	@State var t: Bool = false
	
	init(album: Album?, session: Session, player: Player) {
		self.album = album
		self.session = session
		self.player = player
		
		if let album = album {
			self.tracks = session.getAlbumTracks(albumId: album.id)
		} else {
			self.tracks = nil
		}
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if album == nil {
					HStack {
						Spacer()
					}
					Spacer()
				} else {
					HStack {
						URLImageSourceView(
							album!.getCoverUrl(session: session, resolution: 320)!,
							isAnimationEnabled: true,
							label: Text(album!.title)
						)
							.frame(width: 100, height: 100)
							.onTapGesture {
								let controller = CoverWindowController(rootView:
									URLImageSourceView(
										self.album!.getCoverUrl(session: self.session, resolution: 1280)!,
										isAnimationEnabled: true,
										label: Text(self.album!.title)
									)
								)
								controller.window?.title = self.album!.title
								controller.showWindow(nil)
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(album!.title)
									.font(.title)
									.lineLimit(2)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											CreditsView(album: self.album!, session: self.session)
										)
										controller.window?.title = "Credits – \(self.album!.title)"
										controller.showWindow(nil)
								}
								if self.t || !self.t {
									if self.album!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeAlbum(albumId: self.album!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addAlbum(albumId: self.album!.id)
												self.t.toggle()
										}
									}
								}
							}
							Text(album!.artists?.formArtistString() ?? "")
							if album!.releaseDate != nil {
								Text(DateFormatter.dateOnly.string(from: album!.releaseDate!))
							}
						}
						Spacer()
							.layoutPriority(-1)
						VStack(alignment: .leading) {
							if album!.numberOfTracks != nil {
								Text("\(album!.numberOfTracks!) Tracks")
									.foregroundColor(.secondary)
							}
							if album!.duration != nil {
								Text("\(album!.duration!) sec")
									.foregroundColor(.secondary)
							}
							Spacer()
						}
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
					Divider()
					
					TrackList(tracks: tracks!, showCover: false, showAlbumTrackNumber: true, session: session, player: player)
				}
			}
		}
	}
}

//struct AlbumView_Previews: PreviewProvider {
//
//	static var previews: some View {
//		AlbumView(session: getSession(), album: getAlbum())
////		.frame(width: 500, height: 300)
////			.environment(\.colorScheme, .light)
////		Group {
////			AlbumView()
////				.environment(\.colorScheme, .light)
////			AlbumView()
////				.environment(\.colorScheme, .dark)
////		}
//
//	}
//}
