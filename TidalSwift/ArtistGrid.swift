//
//  ArtistGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct ArtistGrid: View {
	let artists: [Artist]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(artists) { artist in
			ArtistGridItem(artist: artist, session: self.session, player: self.player)
				.onTapGesture(count: 2) {
					print("\(artist.name)")
					self.player.add(artist: artist, .now)
			}
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 200, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct ArtistGridItem: View {
	let artist: Artist
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if artist.getPictureUrl(session: session, resolution: 320) != nil {
				URLImageSourceView(
					artist.getPictureUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(artist.name)
				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					Text(artist.name)
						.multilineTextAlignment(.center)
						.foregroundColor(.white)
				}
			}
			Text(artist.name)
				.frame(width: 160)
		}
		.padding(5)
	}
}

//struct ArtistGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        ArtistGrid()
//    }
//}
