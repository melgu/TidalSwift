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
			
			if session.favorites?.playlists() != nil {
				PlaylistGrid(playlists: favoritePlaylists2Playlists(favoritePlaylists: session.favorites!.playlists()!), session: session, player: player)
			} else {
				Text("Problems fetching favorite playlists")
					.font(.largeTitle)
			}
		}
	}
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
				AlbumGrid(albums: favoriteAlbums2Albums(favoriteAlbums: session.favorites!.albums()!), session: session, player: player)
			} else {
				Text("Problems fetching favorite albums")
				.font(.largeTitle)
			}
		}
	}
}

func favoriteAlbums2Albums(favoriteAlbums: [FavoriteAlbum]) -> [Album] {
	favoriteAlbums.map { $0.item }
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Tracks")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if session.favorites?.tracks() != nil {
				ScrollView {
					HStack {
						VStack(alignment: .leading) {
							ForEach(favoriteTracks2Tracks(favoriteTracks: session.favorites!.tracks()!)) { track in
								TrackRowFront(track: track, showCover: true, session: self.session)
									.onTapGesture(count: 2) {
										print("\(track.title)")
										self.player.add(track: track, .now)
								}
							}
						}
						VStack(alignment: .trailing) {
							ForEach(favoriteTracks2Tracks(favoriteTracks: session.favorites!.tracks()!)) { track in
								TrackRowBack(track: track)
									.onTapGesture(count: 2) {
										print("\(track.title)")
										self.player.add(track: track, .now)
								}
							}
						}
					}
				}
			} else {
				Text("Problems fetching favorite tracks")
				.font(.largeTitle)
			}
		}
	}
}

func favoriteTracks2Tracks(favoriteTracks: [FavoriteTrack]) -> [Track] {
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
		}
	}
}

func favoritePlaylists2Playlists(favoritePlaylists: [FavoritePlaylist]) -> [Playlist] {
	favoritePlaylists.map { $0.item }
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
				ArtistGrid(artists: favoriteArtists2Artists(favoriteArtists: session.favorites!.artists()!), session: session, player: player)
			} else {
				Text("Problems fetching favorite artists")
					.font(.largeTitle)
			}
		}
		
	}
}

func favoriteArtists2Artists(favoriteArtists: [FavoriteArtist]) -> [Artist] {
	favoriteArtists.map { $0.item }
}

//struct Favorites_Previews: PreviewProvider {
//    static var previews: some View {
//        Favorites()
//    }
//}
