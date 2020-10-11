//
//  AlbumGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Grid

struct AlbumGrid: View {
	let albums: [Album]
	let showArtists: Bool
	let showReleaseDate: Bool
	let session: Session
	let player: Player
	
	var rowHeight: CGFloat = 190
	
	init(albums: [Album], showArtists: Bool, showReleaseDate: Bool = false, session: Session, player: Player) {
		self.albums = albums
		self.showArtists = showArtists
		self.showReleaseDate = showReleaseDate
		
		if showArtists {
			rowHeight += 18
		}
		if showReleaseDate {
			rowHeight += 18
		}
		
		self.session = session
		self.player = player
	}
	
	var body: some View {
		if #available(OSX 11.0, *) {
			LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))]) {
				ForEach(albums) { album in
					AlbumGridItem(album: album, showArtists: showArtists, showReleaseDate: showReleaseDate, session: session, player: player)
				}
			}
		} else {
			Grid(albums) { album in
				AlbumGridItem(album: album, showArtists: showArtists, showReleaseDate: showReleaseDate, session: session, player: player)
			}
			.gridStyle(
				ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(rowHeight), spacing: 10)
			)
		}
	}
}
