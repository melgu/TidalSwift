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
	let session: Session
	let albums: [Album]
	
	var body: some View {
//		NavigationView {
			Grid(albums, minimumItemWidth: 160) { album in
				AlbumGridItem(session: self.session, album: album)
//				NavigationLink(destination: AlbumView(session: self.session, album: favoriteAlbum.item)) {
//					AlbumGridItem(session: self.session, album: favoriteAlbum.item)
//				}
			}
//		}
	}
}

struct AlbumGridItem: View {
	let session: Session
	let album: Album
	
    var body: some View {
		VStack {
			if album.getCoverUrl(session: session, resolution: 320) != nil {
				URLImageSourceView(
					album.getCoverUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(album.title)
				)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					Text("Album not\nfound")
						.multilineTextAlignment(.center)
						.foregroundColor(.white)
				}
			}
			Text(album.title)
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
