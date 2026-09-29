//
//  ArtistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ArtistView: View {
	let session: Session
	let player: Player
	let viewState: ViewState
	
	var artist: Artist?
	private var topTracks: [Track] = []
	private var albums: [Album] = []
	private var epsAndSingles: [Album] = []
	private var appearances: [Album] = []
	private var videos: [Video] = []
	
	private enum BottomSectionType {
		case albums
		case epsAndSingles
		case appearances
		case videos
	}
	
	@State private var bottomSectionType: BottomSectionType = .albums
	@State private var isFavorite: Bool? = nil
	
	init(session: Session, player: Player, viewState: ViewState) {
		self.session = session
		self.player = player
		self.viewState = viewState
		
		if let view = viewState.stack.last {
			if let artist = view.artist {
				self.artist = artist
			}
			if let topTracks = view.tracks {
				self.topTracks = topTracks
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
				VStack(alignment: .leading, spacing: 0) {
					headerSection(artist, viewState: viewState)
						.padding(.bottom)
					topTrackSection()
					Divider()
						.padding(.bottom)
					bottomSection(artist)
				}
				.padding(.top, 50) // Has to be 50 instead of 40 like the others to look the same
			} else {
				Text("Couldn't load Artist")
			}
			BackButton()
		}
		.task(id: artist?.id) {
			guard let artist else { return }
			isFavorite = await artist.isInFavorites(session: session)
		}
	}
	
	private func headerSection(_ artist: Artist, viewState: ViewState) -> some View {
		HStack {
		if let pictureUrlSmall = artist.pictureUrl(session: session, resolution: 320),
		   let pictureUrlBig = artist.pictureUrl(session: session, resolution: 750) {
				let picture = AsyncImage(url: pictureUrlSmall)
					.frame(width: 100, height: 100)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				#if canImport(AppKit)
				Button {
					let controller = ImageWindowController(
						imageUrl: pictureUrlBig,
						title: artist.name
					)
					controller.window?.title = artist.name
					controller.showWindow(nil)
				} label: {
					picture
						.accessibilityLabel("Show image in new window")
						.help("Show image in new window")
				}
				.buttonStyle(.plain)
				#else
				picture
					.accessibilityHidden(true)
				#endif
			}
			
			VStack(alignment: .leading) {
				HStack {
					Text(artist.name)
						.font(.title)
						.lineLimit(2)
					#if canImport(AppKit)
					Button {
						let controller = ResizableWindowControllerFactory.create(rootView:
							ArtistBioView(session: session, artist: artist)
								.environment(viewState)
						)
						controller.window?.title = "Bio – \(artist.name)"
						controller.showWindow(nil)
					} label: {
						Image(systemName: "info.circle")
							.accessibilityLabel("Artist Bio")
							.help("Artist Bio")
					}
					.buttonStyle(.plain)
					#endif
					Button {
						if isFavorite ?? true {
							Task {
								print("Remove from Favorites")
								if await session.favorites?.removeArtist(artistId: artist.id) == true {
									isFavorite = false
									viewState.refreshCurrentView()
								}
							}
						} else {
							Task {
								print("Add to Favorites")
								if await session.favorites?.addArtist(artistId: artist.id) == true {
									isFavorite = true
									viewState.refreshCurrentView()
								}
							}
						}
					} label: {
						Image(systemName: isFavorite ?? true ? "heart.fill" : "heart")
							.accessibilityLabel("Favorite")
							.accessibilityAddTraits(isFavorite ?? true ? .isSelected : [])
					}
					.buttonStyle(.plain)
					if let url = artist.url {
						ShareLink(item: url, preview: SharePreview(artist.name)) {
							Image(systemName: "square.and.arrow.up")
								.accessibilityLabel("Share")
								.help("Share")
						}
						.buttonStyle(.plain)
					}
				}
			}
			Spacer(minLength: 0)
				.layoutPriority(-1)
		}
		.frame(height: 100)
		.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
	}
	
	private func topTrackSection() -> some View {
		ScrollView {
			TrackList(tracks: topTracks, showCover: true, showAlbumTrackNumber: false,
					  showArtist: true, showAlbum: true, playlist: nil,
					  session: session, player: player)
		}
		.frame(height: 155)
	}
	
	private func bottomSection(_ artist: Artist) -> some View {
		VStack(spacing: 0) {
			Picker(selection: $bottomSectionType, label: Spacer(minLength: 0)) {
				Text("Albums (\(albums.count))").tag(BottomSectionType.albums)
				Text("EPs & Singles (\(epsAndSingles.count))").tag(BottomSectionType.epsAndSingles)
				Text("Appearances (\(appearances.count))").tag(BottomSectionType.appearances)
				Text("Videos (\(videos.count))").tag(BottomSectionType.videos)
			}
			.pickerStyle(SegmentedPickerStyle())
			.layoutPriority(-1)
			
			ScrollView {
				VStack {
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
				.padding(.top)
			}
		}
		.padding(.horizontal)
	}
}
