//
//  ArtistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct ArtistView: View {
	let artist: Artist?
	let session: Session
	let player: Player
	
	let albums: [Album]?
	let topTracks: [Track]?
	
	@State var t: Bool = false
	
	init(artist: Artist?, session: Session, player: Player) {
		self.artist = artist
		self.session = session
		self.player = player
		
		if let artist = artist {
			self.albums = session.getArtistAlbums(artistId: artist.id)
			self.topTracks = session.getArtistTopTracks(artistId: artist.id, limit: 5, offset: 0)
		} else {
			self.albums = nil
			self.topTracks = nil
		}
	}
	
	var body: some View {
//		ScrollView { // TODO: Comment back in, when Grid supports nesting inside a ScrollView
			VStack(alignment: .leading) {
				if artist == nil {
					HStack {
						Spacer()
					}
					Spacer()
				} else {
					HStack {
						if artist!.getPictureUrl(session: session, resolution: 320) != nil {
							URLImageSourceView(
								artist!.getPictureUrl(session: session, resolution: 320)!,
								isAnimationEnabled: true,
								label: Text(artist!.name)
							)
								.frame(width: 100, height: 100)
								.onTapGesture {
									print("Big Cover")
									let controller = CoverWindowController(rootView:
										URLImageSourceView(
											self.artist!.getPictureUrl(session: self.session, resolution: 750)!,
											isAnimationEnabled: true,
											label: Text(self.artist!.name)
										)
									)
									controller.window?.title = self.artist!.name
									controller.showWindow(nil)
							}
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(artist!.name)
									.font(.title)
									.lineLimit(2)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											ArtistBioView(artist: self.artist!, session: self.session)
										)
										controller.window?.title = "Bio – \(self.artist!.name)"
										controller.showWindow(nil)
								}
								if self.t || !self.t {
									if self.artist!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeArtist(artistId: self.artist!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊷")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addArtist(artistId: self.artist!.id)
												self.t.toggle()
										}
									}
								}
							}
//							Text(playlist!.creator.name ?? "")
//							Text(DateFormatter.dateOnly.string(from: playlist!.lastUpdated))
						}
						Spacer()
							.layoutPriority(-1)
//						VStack(alignment: .leading) {
//							Text("\(playlist!.numberOfTracks) Tracks")
//								.foregroundColor(.secondary)
//							Text("\(playlist!.duration) sec")
//								.foregroundColor(.secondary)
//							Spacer()
//						}
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
					Divider()
					
					TrackList(tracks: topTracks!, showCover: true, session: session, player: player)
					
					AlbumGrid(albums: albums!, showArtists: false, showReleaseDate: true, session: session, player: player)
				}
			}
//		}
	}
}

//struct ArtistView_Previews: PreviewProvider {
//	static var previews: some View {
//		ArtistView()
//	}
//}
