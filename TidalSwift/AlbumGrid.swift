//
//  AlbumGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct AlbumGrid: View {
	let albums: [Album]
	let showArtists: Bool
	let showReleaseDate: Bool
	let session: Session
	let player: Player
	
	init(albums: [Album], showArtists: Bool, showReleaseDate: Bool = false, session: Session, player: Player) {
		self.albums = albums
		self.showArtists = showArtists
		self.showReleaseDate = showReleaseDate
		self.session = session
		self.player = player
	}
	
	var body: some View {
		Grid(albums) { album in
			AlbumGridItem(album: album, showArtists: self.showArtists, showReleaseDate: self.showReleaseDate, session: self.session, player: self.player)
		}
		.gridStyle(
			ModularGridStyle(columns: .min(165), rows: .fixed(showReleaseDate ? 230 : 210), spacing: 5, padding: .init(top: 0, leading: 5, bottom: 5, trailing: 5))
		)
	}
}

struct AlbumGridItem: View {
	let album: Album
	let showArtists: Bool
	let showReleaseDate: Bool
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sc: SessionContainer
	
	init(album: Album, showArtists: Bool, showReleaseDate: Bool = false, session: Session, player: Player) {
		self.album = album
		self.showArtists = showArtists
		self.showReleaseDate = showReleaseDate
		self.session = session
		self.player = player
	}
	
	var body: some View {
		VStack {
			ZStack(alignment: .bottomTrailing) {
				if album.getCoverUrl(session: session, resolution: 320) != nil {
					URLImageSourceView(
						album.getCoverUrl(session: session, resolution: 320)!,
						isAnimationEnabled: true,
						label: Text(album.title)
					)
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				} else {
					ZStack {
						Rectangle()
							.foregroundColor(.black)
							.frame(width: 160, height: 160)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
						if album.streamReady != nil && album.streamReady! {
							Text(album.title)
								.foregroundColor(.white)
								.multilineTextAlignment(.center)
								.lineLimit(5)
								.frame(width: 160)
						} else {
							Text("Album not available")
								.foregroundColor(.white)
								.multilineTextAlignment(.center)
								.frame(width: 160)
						}
					}
				}
				if album.isOffline(session: sc.session) {
					Image("cloud.fill-big")
						.colorInvert()
						.shadow(radius: SHADOWRADIUS)
						.padding(5)
				}
			}
			HStack {
				Text(album.title)
					.lineLimit(1)
				album.attributeHStack
					.padding(.leading, -5)
					.layoutPriority(1)
			}
			.frame(width: 160)
			if showArtists {
				if album.artists != nil {
					Text(album.artists!.formArtistString())
						.fontWeight(.light)
						.foregroundColor(Color.secondary)
						.lineLimit(1)
						.frame(width: 160)
						.padding(.top, album.hasAttributes ? -6.5 : 0)
				} else if album.artist != nil {
					Text(album.artist!.name)
						.fontWeight(.light)
						.foregroundColor(Color.secondary)
						.lineLimit(1)
						.frame(width: 160)
				} else {
					Text("Unknown Artist")
						.fontWeight(.light)
						.foregroundColor(Color.secondary)
						.lineLimit(1)
						.frame(width: 160)
				}
			}
			if showReleaseDate && album.releaseDate != nil {
				Text(DateFormatter.dateOnly.string(from: album.releaseDate!))
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("Second Click. \(self.album.title)")
			self.player.add(album: self.album, .now)
			self.player.play()
		}
		.onTapGesture(count: 1) {
			print("First Click. \(self.album.title)")
			if self.album.streamReady != nil && self.album.streamReady! {
				self.viewState.push(album: self.album)
			}
		}
		.contextMenu {
			AlbumContextMenu(album: self.album, session: session, player: player)
		}
	}
}

struct AlbumContextMenu: View {
	let album: Album
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	@State var t: Bool = false
	
	var body: some View {
		Group {
			Group {
				if album.streamReady != nil && album.streamReady! {
					Button(action: {
						self.player.add(album: self.album, .now)
					}) {
						Text("Play Now")
					}
					Button(action: {
						self.player.add(album: self.album, .next)
					}) {
						Text("Play Next")
					}
					Button(action: {
						self.player.add(album: self.album, .last)
					}) {
						Text("Play Last")
					}
				} else {
					Text("Album not available")
						.italic()
				}
			}
			Divider()
			if album.artists != nil && album.artists![0].name != "Various Artists" {
				Group {
					ForEach(self.album.artists!) { artist in
						Button(action: {
							self.viewState.push(artist: artist)
						}) {
							Text("Go to \(artist.name)")
						}
					}
				}
				Divider()
			}
			Group {
				if t || !t {
					if album.isInFavorites(session: session) ?? false {
						Button(action: {
							print("Remove from Favorites")
							self.session.favorites!.removeAlbum(albumId: self.album.id)
							self.viewState.refreshCurrentView()
							self.t.toggle()
						}) {
							Text("Remove from Favorites")
						}
					} else {
						Button(action: {
							print("Add to Favorites")
							self.session.favorites!.addAlbum(albumId: self.album.id)
							self.t.toggle()
						}) {
							Text("Add to Favorites")
						}
					}
				}
				if album.streamReady != nil && album.streamReady! {
					Button(action: {
						print("Add \(self.album.title) to Playlist")
						if let tracks = self.session.getAlbumTracks(albumId: self.album.id) {
							self.playlistEditingValues.tracks = tracks
							self.playlistEditingValues.showAddTracksModal = true
						}
					}) {
						Text("Add to Playlist …")
					}
					Divider()
					Group {
						if t || !t {
							if self.album.isOffline(session: session) {
								Button(action: {
									print("Remove from Offline")
									self.album.removeOffline(session: self.session)
									self.viewState.refreshCurrentView()
									self.t.toggle()
								}) {
									Text("Remove from Offline")
								}
							} else {
								Button(action: {
									print("Add to Offline")
									self.album.addOffline(session: self.session)
								}) {
									Text("Add to Offline")
								}
							}
						}
						
						Button(action: {
							print("Download")
							DispatchQueue.global(qos: .background).async {
								_ = self.session.helpers.download(album: self.album)
							}
						}) {
							Text("Download")
						}
					}
					Divider()
					if album.getCoverUrl(session: self.session, resolution: 1280) != nil {
						Button(action: {
							print("Cover")
							let controller = CoverWindowController(rootView:
								URLImageSourceView(
									self.album.getCoverUrl(session: self.session, resolution: 1280)!,
									isAnimationEnabled: true,
									label: Text(self.album.title)
								)
							)
							controller.window?.title = self.album.title
							controller.showWindow(nil)
						}) {
							Text("Cover")
						}
					}
					Button(action: {
						print("Credits")
						let controller = ResizableWindowController(rootView:
							CreditsView(session: self.session, album: self.album)
								.environmentObject(self.viewState)
						)
						controller.window?.title = "Credits – \(self.album.title)"
						controller.showWindow(nil)
					}) {
						Text("Credits")
					}
					if album.url != nil {
						Button(action: {
							print("Share")
							Pasteboard.copy(string: self.album.url!.absoluteString)
						}) {
							Text("Share")
						}
					}
				}
			}
		}
	}
}

extension Album {
	var attributeHStack: some View {
		HStack {
			if self.explicit ?? false {
				Image("e.square")
			}
			if self.audioQuality == .master {
				Image("m.square.fill")
			} else if self.audioModes?.contains(.sony360RealityAudio) ?? false {
				Image("headphones")
			}
		}
		.secondaryIconColor()
	}
	
	var hasAttributes: Bool {
		return self.explicit ?? false || self.audioQuality == .master || self.audioModes?.contains(.sony360RealityAudio) ?? false
	}
}
