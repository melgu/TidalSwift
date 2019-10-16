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
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Playlists")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if session.favorites?.playlists(order: .dateAdded, orderDirection: .descending) != nil {
				PlaylistGrid(playlists: favoritePlaylists2Playlists(session.favorites!.playlists()!), session: session, player: player)
			} else {
				Text("Problems fetching favorite playlists")
					.font(.largeTitle)
			}
		}
	}
}

func favoritePlaylists2Playlists(_ favoritePlaylists: [FavoritePlaylist]) -> [Playlist] {
	favoritePlaylists.map { $0.item }
}

struct FavoriteAlbums: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Albums")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if session.favorites?.playlists() != nil {
				AlbumGrid(albums: favoriteAlbums2Albums(session.favorites!.albums(order: .dateAdded, orderDirection: .descending)!),
						  showArtists: true, session: session, player: player)
			} else {
				Text("Problems fetching favorite albums")
				.font(.largeTitle)
			}
		}
	}
}

func favoriteAlbums2Albums(_ favoriteAlbums: [FavoriteAlbum]) -> [Album] {
	favoriteAlbums.map { $0.item }
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	let tracks: [Track]?
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		
		if let favTracks = session.favorites?.tracks(order: .dateAdded, orderDirection: .descending) {
			self.tracks = favoriteTracks2Tracks(favTracks)
		} else {
			self.tracks = nil
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Tracks")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if tracks != nil {
				ScrollView {
					TrackList(tracks: tracks!, showCover: true, session: session, player: player)
				}
			} else {
				Text("Problems fetching favorite tracks")
				.font(.largeTitle)
				Spacer()
			}
		}
	}
}

func favoriteTracks2Tracks(_ favoriteTracks: [FavoriteTrack]) -> [Track] {
	favoriteTracks.map { $0.item }
}

struct FavoriteVideos: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Videos")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if session.favorites?.playlists() != nil {
				VideoGrid(videos: favoriteVideos2Videos(session.favorites!.videos(order: .dateAdded, orderDirection: .descending)!),
						  showArtists: true, session: session, player: player)
			} else {
				Text("Problems fetching favorite videos")
				.font(.largeTitle)
			}
		}
	}
}

func favoriteVideos2Videos(_ favoriteVideos: [FavoriteVideo]) -> [Video] {
	favoriteVideos.map { $0.item }
}

struct FavoriteArtists: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Artists")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if session.favorites?.artists() != nil {
				ArtistGrid(artists: favoriteArtists2Artists(session.favorites!.artists()!), session: session, player: player)
			} else {
				Text("Problems fetching favorite artists")
					.font(.largeTitle)
			}
		}
		
	}
}

func favoriteArtists2Artists(_ favoriteArtists: [FavoriteArtist]) -> [Artist] {
	favoriteArtists.map { $0.item }
}

//struct Favorites_Previews: PreviewProvider {
//    static var previews: some View {
//        Favorites()
//    }
//}
