//
//  PlaylistGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Grid

struct PlaylistGrid: View {
	let playlists: [Playlist]
	let session: Session
	let player: Player
	
	var body: some View {
		if #available(OSX 11.0, *) {
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))]) {
						ForEach(playlists) { playlist in
							PlaylistGridItem(playlist: playlist, session: session, player: player)
						}
					}
				} else {
					Grid(playlists) { playlist in
						PlaylistGridItem(playlist: playlist, session: session, player: player)
					}
					.gridStyle(
						ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(200), spacing: 10)
					)
				}
		
	}
}
