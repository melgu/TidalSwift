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
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Playlists")
					.font(.largeTitle)
				Spacer()
			}
			.padding([.horizontal, .bottom])
			
			if viewState.stack.last?.playlists != nil {
				if viewState.stack.last!.playlists!.isEmpty {
					Text("None")
						.font(.callout)
						.padding(.horizontal)
				} else {
					PlaylistGrid(playlists: viewState.stack.last!.playlists!, session: session, player: player)
				}
			}
			Spacer(minLength: 0)
		}
	}
}

struct OfflineAlbumsView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Albums")
					.font(.largeTitle)
				Spacer()
			}
			.padding([.horizontal, .bottom])
			
			if viewState.stack.last?.albums != nil {
				if viewState.stack.last!.albums!.isEmpty {
					Text("None")
						.font(.callout)
						.padding(.horizontal)
				} else {
					AlbumGrid(albums: viewState.stack.last!.albums!, showArtists: true, session: session, player: player)
				}
			}
			Spacer(minLength: 0)
		}
	}
}

struct OfflineTracksView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Offline Tracks")
					.font(.largeTitle)
				Spacer()
			}
			.padding([.horizontal, .bottom])
			
			if viewState.stack.last?.tracks != nil {
				if viewState.stack.last!.tracks!.isEmpty {
					Text("None")
						.font(.callout)
						.padding(.horizontal)
				} else {
					ScrollView {
						TrackList(wrappedTracks: viewState.stack.last!.tracks!.wrapped(), showCover: true, showAlbumTrackNumber: false, showArtist: true, showAlbum: true, playlist: nil, session: session, player: player)
					}
				}
			}
			Spacer(minLength: 0)
		}
	}
}
