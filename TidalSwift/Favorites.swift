//
//  Favorites.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct FavoritePlaylists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Playlists")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.playlists != nil {
				PlaylistGrid(playlists: viewState.stack.last!.playlists!, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

func favoritePlaylists2Playlists(_ favoritePlaylists: [FavoritePlaylist]) -> [Playlist] {
	let tempPlaylists = favoritePlaylists.map { $0.playlist }
	
	// Playlists can appear as userCreated and userFavorited
	// Only keep one
	var resultArray: [Playlist] = []
	for playlist in tempPlaylists {
		if !resultArray.contains(playlist) {
			resultArray.append(playlist)
		}
	}
	return resultArray
}

struct FavoriteAlbums: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Albums")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.albums != nil {
				AlbumGrid(albums: viewState.stack.last!.albums!, showArtists: true, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

func favoriteAlbums2Albums(_ favoriteAlbums: [FavoriteAlbum]) -> [Album] {
	favoriteAlbums.map { $0.item }
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Tracks")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				if session.helpers?.offline.saveFavoritesOffline ?? false {
					Text("􀇃")
						.font(.title)
						.onTapGesture {
							print("Remove from Offline")
							self.session.helpers?.offline.saveFavoritesOffline = false
							self.session.helpers?.offline.syncFavoriteTracks()
							self.viewState.refreshCurrentView()
					}
				} else {
					Text("􀇂")
						.font(.title)
						.onTapGesture {
							print("Add to Offline")
							self.session.helpers?.offline.saveFavoritesOffline = true
							self.session.helpers?.offline.syncFavoriteTracks()
							self.viewState.refreshCurrentView()
					}
				}
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.tracks != nil {
				ScrollView {
					TrackList(wrappedTracks: viewState.stack.last!.tracks!.wrap(), showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
			}
			Spacer(minLength: 0)
		}
	}
}

func favoriteTracks2Tracks(_ favoriteTracks: [FavoriteTrack]) -> [Track] {
	favoriteTracks.map { $0.item }
}

struct FavoriteVideos: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Videos")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.videos != nil {
				VideoGrid(videos: viewState.stack.last!.videos!,
						  showArtists: true, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

func favoriteVideos2Videos(_ favoriteVideos: [FavoriteVideo]) -> [Video] {
	favoriteVideos.map { $0.item }
}

struct FavoriteArtists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Artists")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.artists != nil {
				ArtistGrid(artists: viewState.stack.last!.artists!, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

func favoriteArtists2Artists(_ favoriteArtists: [FavoriteArtist]) -> [Artist] {
	favoriteArtists.map { $0.item }
}
