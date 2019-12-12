//
//  SearchView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.09.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

struct SearchView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	init(session: Session, player: Player) {
		print("init SearchView")
		self.session = session
		self.player = player
	}
	
	var body: some View {
		return ScrollView([.vertical]) {
			VStack(alignment: .leading) {
				HStack {
					Text("Search")
						.font(.largeTitle)
					Spacer()
					LoadingSpinner()
				}
				.padding([.horizontal, .bottom])
				
				if viewState.stack.last?.searchResponse != nil {
					if !viewState.stack.last!.searchResponse!.artists.isEmpty {
						SearchViewArtists(artists: viewState.stack.last!.searchResponse!.artists, session: session, player: player)
						Divider()
					}
					if !viewState.stack.last!.searchResponse!.albums.isEmpty {
						SearchViewAlbums(albums: viewState.stack.last!.searchResponse!.albums, session: session, player: player)
						Divider()
					}
					if !viewState.stack.last!.searchResponse!.playlists.isEmpty {
						SearchViewPlaylists(playlists: viewState.stack.last!.searchResponse!.playlists, session: session, player: player)
						Divider()
					}
					if !viewState.stack.last!.searchResponse!.tracks.isEmpty {
						SearchViewTracks(tracks: viewState.stack.last!.searchResponse!.tracks, session: session, player: player)
						Divider()
					}
					if !viewState.stack.last!.searchResponse!.videos.isEmpty {
						SearchViewVideos(videos: viewState.stack.last!.searchResponse!.videos, session: session, player: player)
					}
					if viewState.stack.last!.searchResponse!.artists.isEmpty
						&& viewState.stack.last!.searchResponse!.albums.isEmpty
						&& viewState.stack.last!.searchResponse!.playlists.isEmpty
						&& viewState.stack.last!.searchResponse!.tracks.isEmpty
						&& viewState.stack.last!.searchResponse!.videos.isEmpty {
						Text("No Results")
							.font(.callout)
					}
				}
				Spacer(minLength: 0)
			}
		}
	}
}

struct SearchViewArtists: View {
	let artists: [Artist]
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Artists")
				.font(.title)
				.padding(.horizontal)
			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(artists) { artist in
						ArtistGridItem(artist: artist, session: self.session, player: self.player)
					}
				}
				.padding(10)
			}
		}
	}
}

struct SearchViewAlbums: View {
	let albums: [Album]
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Albums")
				.font(.title)
				.padding(.horizontal)
			
			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(albums) { album in
						AlbumGridItem(album: album, showArtists: true, session: self.session, player: self.player)
					}
				}
				.padding(10)
			}
		}
	}
}

struct SearchViewPlaylists: View {
	let playlists: [Playlist]
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Playlists")
				.font(.title)
				.padding(.horizontal)
			
			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(playlists) { playlist in
						PlaylistGridItem(playlist: playlist, session: self.session, player: self.player)
					}
				}
				.padding(10)
			}
		}
	}
}

struct SearchViewTracks: View {
	let tracks: [Track]
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Tracks")
				.font(.title)
				.padding(.horizontal)
			
			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(tracks) { track in
						TrackGridItem(track: track, showArtist: true, session: self.session, player: self.player)
					}
				}
				.padding(10)
			}
		}
	}
}

struct SearchViewVideos: View {
	let videos: [Video]
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Videos")
				.font(.title)
				.padding(.horizontal)
			
			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(videos) { video in
						VideoGridItem(video: video, showArtist: true, session: self.session, player: self.player)
					}
				}
				.padding(10)
			}
		}
	}
}
