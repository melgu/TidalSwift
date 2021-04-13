//
//  ArtistGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct ArtistGridItem: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			if let pictureUrl = artist.getPictureUrl(session: session, resolution: 320) {
				URLImageSourceView(
					pictureUrl,
					isAnimationEnabled: true,
					label: Text(artist.name)
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
		.toolTip(artist.name)
		.onTapGesture(count: 2) {
			print("\(artist.name)")
			player.add(artist: artist, .now)
		}
		.onTapGesture(count: 1) {
			print("First Click. \(artist.name)")
			viewState.push(artist: artist)
		}
		.contextMenu {
			ArtistContextMenu(artist: artist, session: session, player: player)
		}
	}
}
