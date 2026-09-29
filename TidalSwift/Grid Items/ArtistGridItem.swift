//
//  ArtistGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ArtistGridItem: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	
	var body: some View {
		VStack {
			if let pictureUrl = artist.pictureUrl(session: session, resolution: 320) {
				AsyncImage(url: pictureUrl)
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
					Text(artist.name)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(5)
						.frame(width: 160)
				}
			}
			Text(artist.name)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.help(artist.name)
		.onTapGesture(count: 2, perform: play)
		.onTapGesture(count: 1, perform: open)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(.default, open)
		.accessibilityAction(named: "Play", play)
		.contextMenu {
			ArtistContextMenu(artist: artist, session: session, player: player)
		}
	}
	
	private func open() {
		print("First Click. \(artist.name)")
		viewState.push(artist: artist)
	}
	
	private func play() {
		print("\(artist.name)")
		player.add(artist: artist, .now)
	}
}
