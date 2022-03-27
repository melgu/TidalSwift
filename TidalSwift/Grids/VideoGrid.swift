//
//  VideoGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct VideoGrid: View {
	let videos: [Video]
	let showArtists: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		if #available(macOS 11.0, *) {
			LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))]) {
				ForEach(videos) { video in
					VideoGridItem(video: video, showArtist: showArtists, session: session, player: player)
				}
			}
		} else {
			Grid(videos) { video in
				VideoGridItem(video: video, showArtist: showArtists, session: session, player: player)
			}
			.gridStyle(
				ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(210), spacing: 10)
			)
		}
	}
}
