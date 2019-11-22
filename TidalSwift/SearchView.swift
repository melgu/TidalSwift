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
	
	@State var searchResult: SearchResponse?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	@State var lastSearchTerm: String?
	@EnvironmentObject var viewState: ViewState
	
	init(session: Session, player: Player) {
		print("init SearchView")
		self.session = session
		self.player = player
	}
	
	var body: some View {
		_ = viewState.$searchTerm.receive(on: DispatchQueue.main).sink(receiveValue: doSearch(searchTerm:))
		return ScrollView([.vertical]) {
			VStack(alignment: .leading) {
				if loadingState == .successful {
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
				} else if loadingState == .loading {
					LoadingSpinner()
				} else {
					Spacer()
					Text("Problems searching.")
						.font(.largeTitle)
				}
				Spacer()
			}
		}
		.onAppear() {
			self.doSearch(searchTerm: self.viewState.searchTerm)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func doSearch(searchTerm: String) {
		if searchTerm == lastSearchTerm || searchTerm.isEmpty {
			return
		}
		lastSearchTerm = searchTerm
		workItem?.cancel()
		loadingState = .loading
		workItem = createWorkItem()
		if workItem != nil {
			DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			let t = self.session.search(for: self.viewState.searchTerm)
			DispatchQueue.main.async {
				if t != nil {
					self.searchResult = t
					self.loadingState = .successful
				} else {
					self.loadingState = .error
				}
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
