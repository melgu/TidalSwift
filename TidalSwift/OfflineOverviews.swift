//
//  OfflineOverviews.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.01.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct OfflinePlaylistsView: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Playlists")
					.font(.largeTitle)
				Spacer()
			}
			.padding(.horizontal)
			
			PlaylistGrid(playlists: session.helpers.offline.allOfflinePlaylists(), session: session, player: player)
			Spacer(minLength: 0)
		}
	}
}

struct OfflineAlbumsView: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Albums")
					.font(.largeTitle)
				Spacer()
			}
			.padding(.horizontal)
			
			AlbumGrid(albums: session.helpers.offline.allOfflineAlbums(), showArtists: true, session: session, player: player)
			Spacer(minLength: 0)
		}
	}
}

struct OfflineTracksView: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Tracks")
					.font(.largeTitle)
				Spacer()
			}
			.padding(.horizontal)
			
			ScrollView {
				TrackList(wrappedTracks: session.helpers.offline.allOfflineTracks().wrapped(), showCover: true, showAlbumTrackNumber: false, showArtist: true, showAlbum: true, playlist: nil, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}
