//
//  AlbumGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AlbumGridItem: View {
	let album: Album
	let showArtists: Bool
	let showReleaseDate: Bool
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
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
				if let albumUrl = album.getCoverUrl(session: session, resolution: 320) {
					AsyncImage(url: albumUrl) { image in
						image.resizable().scaledToFit()
					} placeholder: {
						Rectangle()
					}
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
					.accessibilityHidden(true)
				} else {
					ZStack {
						Rectangle()
							.foregroundColor(.black)
							.frame(width: 160, height: 160)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
						if album.streamReady ?? false {
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
				if album.isOffline(session: session) {
					Image(systemName: "cloud.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 30)
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
				if let artists = album.artists { // Multiple Artists
					Text(artists.formArtistString())
						.fontWeight(.light)
						.foregroundColor(Color.secondary)
						.lineLimit(1)
						.frame(width: 160)
						.padding(.top, album.hasAttributes ? -6.5 : 0)
				} else if let artist = album.artist { // Single Artist
					Text(artist.name)
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
			if showReleaseDate, let releaseDate = album.releaseDate {
				Text(DateFormatter.dateOnly.string(from: releaseDate))
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.toolTip(toolTipString)
		.onTapGesture(count: 2) {
			print("Second Click. \(album.title)")
			player.add(album: album, .now)
		}
		.onTapGesture(count: 1) {
			print("First Click. \(album.title)")
			if album.streamReady ?? false {
				viewState.push(album: album)
			}
		}
		.contextMenu {
			AlbumContextMenu(album: album, session: session, player: player)
		}
	}
	
	var toolTipString: String {
		var s = album.title
		if let artists = album.artists {
			s += " – \(artists.formArtistString())"
		}
		return s
	}
}

extension Album {
	var attributeHStack: some View {
		HStack {
			if explicit ?? false {
				Image(systemName: "e.square")
			}
			if audioQuality == .master {
				Image(systemName: "m.square.fill")
			} else if audioModes?.contains(.sony360RealityAudio) ?? false {
				Image(systemName: "headphones")
			} else if audioModes?.contains(.dolbyAtmos) ?? false {
				Image(systemName: "hifispeaker.fill")
			} else {
				Text("")
			}
		}
		.secondaryIconColor()
	}
	
	var hasAttributes: Bool {
		explicit ?? false ||
			audioQuality == .master ||
			audioModes?.contains(.sony360RealityAudio) ?? false ||
			audioModes?.contains(.dolbyAtmos) ?? false
	}
}
