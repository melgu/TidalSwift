//
//  NewReleases.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Grid

struct NewReleases: View {
	let session: Session
	let player: Player
	
	let albums: [Album]?
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		self.albums = session.helpers?.newReleasesFromFavoriteArtists(number: 40)
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("New Releases")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if albums != nil {
				AlbumGrid(albums: albums!, showArtists: true, showReleaseDate: true, session: session, player: player)
			} else {
				Text("Problems fetching favorite albums")
				.font(.largeTitle)
			}
		}
	}
}
