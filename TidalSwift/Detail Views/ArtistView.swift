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
	
	enum BottomSectionType {
		case albums
		case epsAndSingles
		case appearances
		case videos
	}
	
	@State var bottomSectionType: BottomSectionType = .albums
	
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
			// TODO: Bring ScroolView back in?
			if let artist = artist {
				VStack(alignment: .leading) {
					headerSection(artist, viewState: viewState)
					topTrackSection()
					Divider()
					bottomSection(artist)
				}
				.padding(.top, 50) // Has to be 50 instead of 40 like the others to look the same
			}  else {
				Text("Couldn't load Artist")
			}
			BackButton()
		}
	}
	
	func headerSection(_ artist: Artist, viewState: ViewState) -> some View {
		HStack {
			if let pictureUrlSmall = artist.getPictureUrl(session: session, resolution: 320),
			   let pictureUrlBig = artist.getPictureUrl(session: session, resolution: 750) {
				URLImageSourceView(
					pictureUrlSmall,
					isAnimationEnabled: true,
					label: Text(artist.name)
				)
				.frame(width: 100, height: 100)
				.cornerRadius(CORNERRADIUS)
				.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				.toolTip("Show image in new window")
				.onTapGesture {
					let controller = ImageWindowController(
						imageUrl: pictureUrlBig,
						title: artist.name
					)
					controller.window?.title = artist.name
					controller.showWindow(nil)
				}
			}
			
			VStack(alignment: .leading) {
				HStack {
					Text(artist.name)
						.font(.title)
						.lineLimit(2)
					Image("info.circle")
						.primaryIconColor()
						.toolTip("Artist Bio")
						.onTapGesture {
							let controller = ResizableWindowController(rootView:
								ArtistBioView(session: session, artist: artist)
																		.environmentObject(viewState)
							)
							controller.window?.title = "Bio – \(artist.name)"
							controller.showWindow(nil)
						}
					if artist.isInFavorites(session: session) ?? true {
						Image("heart.fill")
							.primaryIconColor()
							.onTapGesture {
								print("Remove from Favorites")
								session.favorites?.removeArtist(artistId: artist.id)
								viewState.refreshCurrentView()
							}
					} else {
						Image("heart")
							.primaryIconColor()
							.onTapGesture {
								print("Add to Favorites")
								session.favorites?.addArtist(artistId: artist.id)
								viewState.refreshCurrentView()
							}
					}
					if let url = artist.url {
						Image("square.and.arrow.up")
							.primaryIconColor()
							.toolTip("Copy URL")
							.onTapGesture {
								Pasteboard.copy(string: url.absoluteString)
							}
					}
				}
			}
			Spacer(minLength: 0)
				.layoutPriority(-1)
		}
		.frame(height: 100)
		.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
	}
	
	func topTrackSection() -> some View {
		ScrollView {
			TrackList(wrappedTracks: topTracks, showCover: true, showAlbumTrackNumber: false,
					  showArtist: true, showAlbum: true, playlist: nil,
					  session: session, player: player)
		}
		.frame(height: 155)
	}
	
	func bottomSection(_ artist: Artist) -> some View {
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
}
