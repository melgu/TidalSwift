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
		ScrollView(.vertical) {
			VStack(alignment: .leading) {
				HStack {
					Text("Search")
						.font(.largeTitle)
					Spacer()
					LoadingSpinner()
				}
				.padding([.horizontal, .bottom])
				
				if let searchResponse = viewState.stack.last?.searchResponse {
					if !searchResponse.artists.isEmpty {
						SearchViewArtists(artists: searchResponse.artists, session: session, player: player)
						Divider()
					}
					if !searchResponse.albums.isEmpty {
						SearchViewAlbums(albums: searchResponse.albums, session: session, player: player)
						Divider()
					}
					if !searchResponse.playlists.isEmpty {
						SearchViewPlaylists(playlists: searchResponse.playlists, session: session, player: player)
						Divider()
					}
					if !searchResponse.tracks.isEmpty {
						SearchViewTracks(tracks: searchResponse.tracks, session: session, player: player)
						Divider()
					}
					if !searchResponse.videos.isEmpty {
						SearchViewVideos(videos: searchResponse.videos, session: session, player: player)
					}
					if searchResponse.artists.isEmpty
						&& searchResponse.albums.isEmpty
						&& searchResponse.playlists.isEmpty
						&& searchResponse.tracks.isEmpty
						&& searchResponse.videos.isEmpty {
						Text("No Results")
							.font(.callout)
							.padding(.horizontal)
					}
				}
				Spacer(minLength: 0)
			}
			.padding(.vertical)
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
				if #available(OSX 11.0, *) {
					LazyHStack(alignment: .top) {
						ForEach(artists) { artist in
							ArtistGridItem(artist: artist, session: session, player: player)
						}
					}
					.padding(10)
				} else {
					HStack(alignment: .top) {
						ForEach(artists) { artist in
							ArtistGridItem(artist: artist, session: session, player: player)
						}
					}
					.padding(10)
				}
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
				if #available(OSX 11.0, *) {
					LazyHStack(alignment: .top) {
						ForEach(albums) { album in
							AlbumGridItem(album: album, showArtists: true, session: session, player: player)
						}
					}
					.padding(10)
				} else {
					HStack(alignment: .top) {
						ForEach(albums) { album in
							AlbumGridItem(album: album, showArtists: true, session: session, player: player)
						}
					}
					.padding(10)
				}
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
				if #available(OSX 11.0, *) {
					LazyHStack(alignment: .top) {
						ForEach(playlists) { playlist in
							PlaylistGridItem(playlist: playlist, session: session, player: player)
						}
					}
					.padding(10)
				} else {
					HStack(alignment: .top) {
						ForEach(playlists) { playlist in
							PlaylistGridItem(playlist: playlist, session: session, player: player)
						}
					}
					.padding(10)
				}
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
				if #available(OSX 11.0, *) {
					LazyHStack(alignment: .top) {
						ForEach(tracks) { track in
							TrackGridItem(track: track, showArtist: true, session: session, player: player)
						}
					}
					.padding(10)
				} else {
					HStack(alignment: .top) {
						ForEach(tracks) { track in
							TrackGridItem(track: track, showArtist: true, session: session, player: player)
						}
					}
					.padding(10)
				}
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
				if #available(OSX 11.0, *) {
					LazyHStack(alignment: .top) {
						ForEach(videos) { video in
							VideoGridItem(video: video, showArtist: true, session: session, player: player)
						}
					}
					.padding(10)
				} else {
					HStack(alignment: .top) {
						ForEach(videos) { video in
							VideoGridItem(video: video, showArtist: true, session: session, player: player)
						}
					}
					.padding(10)
				}
			}
		}
	}
}
