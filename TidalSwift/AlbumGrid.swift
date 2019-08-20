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
	var session: Session
	
	var body: some View {
//		NavigationView {
			Grid(session.favorites!.albums()!, minimumItemWidth: 160) { favoriteAlbum in
				AlbumGridItem(session: self.session, album: favoriteAlbum.item)
//				NavigationLink(destination: AlbumView(session: self.session, album: favoriteAlbum.item)) {
//					AlbumGridItem(session: self.session, album: favoriteAlbum.item)
//				}
			}
//		}
	}
}

struct AlbumGridItem: View {
	var session: Session
	var album: Album
	
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

#if DEBUG
//struct AlbumGrid_Previews: PreviewProvider {
//	static var previews: some View {
//		AlbumGrid()
//	}
//}
#endif
