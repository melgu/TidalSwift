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
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(albums) { album in
			AlbumGridItem(album: album, session: self.session, player: self.player)
				.onTapGesture(count: 2) {
					print("\(album.title)")
					self.player.add(album: album, .now)
			}
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 200, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct AlbumGridItem: View {
	let album: Album
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if album.getCoverUrl(session: session, resolution: 320) != nil {
				Rectangle()
//				URLImageSourceView(
//					album.getCoverUrl(session: session, resolution: 320)!,
//					isAnimationEnabled: true,
//					label: Text(album.title)
//				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					if album.streamReady != nil && album.streamReady! {
						Text(album.title)
							.multilineTextAlignment(.center)
							.foregroundColor(.white)
					} else {
						Text("Album not available")
							.multilineTextAlignment(.center)
							.foregroundColor(.white)
					}
				}
			}
			Text(album.title)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
	}
}

//struct AlbumGrid_Previews: PreviewProvider {
//	static var previews: some View {
//		AlbumGrid()
//	}
//}
