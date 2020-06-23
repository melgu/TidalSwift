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
	let session: Session
	let player: Player
	let viewState: ViewState
	
	var artist: Artist?
	var topTracks: [WrappedTrack] = []
	var albums: [Album] = []
	var epsAndSingles: [Album] = []
	var appearances: [Album] = []
	var videos: [Video] = []
	
//	@EnvironmentObject var viewState: ViewState
	
	enum BottomSectionType {
		case albums
		case epsAndSingles
		case appearances
		case videos
	}
	
	@State var bottomSectionType: BottomSectionType = .albums
	@State var t: Bool = false
	
	init(session: Session, player: Player, viewState: ViewState) {
		self.session = session
		self.player = player
		self.viewState = viewState
		
		if let view = viewState.stack.last {
			if let artist = view.artist {
				self.artist = artist
			}
			if let topTracks = view.tracks {
				self.topTracks = topTracks.wrapped()
			}
			if let albums = view.albums {
				self.albums = albums
			}
			if let epsAndSingles = view.albumsEpsAndSingles {
				self.epsAndSingles = epsAndSingles
			}
			if let appearances = view.albumsAppearances {
				self.appearances = appearances
			}
			if let videos = view.videos {
				self.videos = videos
			}
		}
	}
	
	var body: some View {
		ZStack {
//			ScrollView { // TODO: Comment back in, when Grid supports nesting inside a ScrollView
			VStack(alignment: .leading) {
				HStack {
					if artist!.getPictureUrl(session: session, resolution: 320) != nil {
						URLImageSourceView(
							artist!.getPictureUrl(session: session, resolution: 320)!,
							isAnimationEnabled: true,
							label: Text(artist!.name)
						)
							.frame(width: 100, height: 100)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
							.toolTip("Show image in new window")
							.onTapGesture {
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
							Image("info.circle")
								.primaryIconColor()
								.toolTip("Artist Bio")
								.onTapGesture {
									let controller = ResizableWindowController(rootView:
																				ArtistBioView(session: self.session, artist: self.artist!)
																				.environmentObject(self.viewState)
									)
									controller.window?.title = "Bio – \(self.artist!.name)"
									controller.showWindow(nil)
								}
							if t || !t {
								if artist!.isInFavorites(session: session) ?? true {
									Image("heart.fill")
										.primaryIconColor()
										.onTapGesture {
											print("Remove from Favorites")
											self.session.favorites!.removeArtist(artistId: self.artist!.id)
											self.t.toggle()
										}
								} else {
									Image("heart")
										.primaryIconColor()
										.onTapGesture {
											print("Add to Favorites")
											self.session.favorites!.addArtist(artistId: self.artist!.id)
											self.t.toggle()
										}
								}
							}
							if artist!.url != nil {
								Image("square.and.arrow.up")
									.primaryIconColor()
									.toolTip("Copy URL")
									.onTapGesture {
										Pasteboard.copy(string: self.artist!.url!.absoluteString)
									}
							}
						}
					}
					Spacer(minLength: 0)
						.layoutPriority(-1)
				}
				.frame(height: 100)
				.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
				
				ScrollView {
					TrackList(wrappedTracks: topTracks, showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
				.frame(height: 155)
				
				Divider()
				
				VStack {
					HStack {
						Picker(selection: $bottomSectionType, label: Spacer(minLength: 0)) {
							Text("Albums (\(albums.count))").tag(BottomSectionType.albums)
							Text("EPs & Singles (\(epsAndSingles.count))").tag(BottomSectionType.epsAndSingles)
							Text("Appearances (\(appearances.count))").tag(BottomSectionType.appearances)
							Text("Videos (\(videos.count))").tag(BottomSectionType.videos)
						}
						.pickerStyle(SegmentedPickerStyle())
					}
					ScrollView {
						if bottomSectionType == .albums {
							AlbumGrid(albums: albums, showArtists: false, showReleaseDate: true, session: session, player: player)
						} else if bottomSectionType == .epsAndSingles {
							AlbumGrid(albums: epsAndSingles, showArtists: false, showReleaseDate: true, session: session, player: player)
						} else if bottomSectionType == .appearances {
							AlbumGrid(albums: appearances, showArtists: false, showReleaseDate: true, session: session, player: player)
						} else if bottomSectionType == .videos {
							VideoGrid(videos: videos, showArtists: false, session: session, player: player)
						}
					}
					Spacer(minLength: 0)
				}
				.padding(.horizontal)
			}
				.padding(.top, 50) // Has to be 50 instead of 40 like the others to look the same
			//			}
			BackButton()
		}
	}
}
