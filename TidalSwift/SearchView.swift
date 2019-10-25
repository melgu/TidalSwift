//
//  SearchView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.09.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct SearchView: View {
	let searchResult: SearchResponse?
	let session: Session
	let player: Player
	
	init(searchText: String, session: Session, player: Player) {
		print("init SearchView: \(searchText)")
		self.session = session
		self.player = player
		searchResult = session.search(for: searchText)
	}
	
	var body: some View {
		
		ScrollView([.vertical]) {
			VStack(alignment: .leading) {
				if searchResult != nil {
					if !searchResult!.artists.isEmpty {
						SearchViewArtists(artists: searchResult!.artists, session: session, player: player)
						Divider()
					}
					if !searchResult!.albums.isEmpty {
						SearchViewAlbums(albums: searchResult!.albums, session: session, player: player)
						Divider()
					}
					if !searchResult!.playlists.isEmpty {
						SearchViewPlaylists(playlists: searchResult!.playlists, session: session, player: player)
						Divider()
					}
					if !searchResult!.tracks.isEmpty {
						SearchViewTracks(tracks: searchResult!.tracks, session: session, player: player)
						Divider()
					}
					if !searchResult!.videos.isEmpty {
						SearchViewVideos(videos: searchResult!.videos, session: session, player: player)
					}
					if searchResult!.artists.isEmpty && searchResult!.albums.isEmpty && searchResult!.playlists.isEmpty &&
					   searchResult!.tracks.isEmpty && searchResult!.videos.isEmpty {
						Text("No Results")
							.font(.callout)
					}
				} else {
					Spacer()
					Text("Problems searching.")
						.font(.callout)
				}
				Spacer()
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
				.font(.largeTitle)
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
				.font(.largeTitle)
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
				.font(.largeTitle)
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
				.font(.largeTitle)
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
				.font(.largeTitle)
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

//public let artists: [Artist]
//public let albums: [Album]
//public let playlists: [Playlist]
//public let tracks: [Track]
//public let videos: [Video]
//public let topHit: TopHit?

//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
//}
