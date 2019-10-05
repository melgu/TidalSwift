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
				AlbumGrid(albums: favoriteAlbums2Albums(favoriteAlbums: session.favorites!.albums(order: .releaseDate, orderDirection: .descending)!),
						  showArtists: true, session: session, player: player)
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
	
	let tracks: [Track]?
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		
		if let favTracks = session.favorites?.tracks() {
			self.tracks = favoriteTracks2Tracks(favoriteTracks: favTracks)
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
					HStack {
						VStack(alignment: .leading) {
							ForEach(0..<tracks!.count) { i in
								TrackRowFront(track: self.tracks![i], showCover: true, session: self.session)
									.onTapGesture(count: 2) {
										print("\(self.tracks![i].title)")
										self.player.add(tracks: self.tracks!, .now)
										self.player.play(atIndex: i)
									}
									.contextMenu {
										Button(action: {
											self.player.add(track: self.tracks![i], .now)
										}) {
											Text("Play now")
										}
										Button(action: {
											self.player.add(track: self.tracks![i], .next)
										}) {
											Text("Play next")
										}
										Button(action: {
											self.player.add(track: self.tracks![i], .last)
										}) {
											Text("Play last")
										}
//										Divider()
//										Button(action: {
//											print("Remove from Favorites")
//										}) {
//											Text("Remove from Favorites")
//										}
//										Button(action: {
//											print(" to Playlist …")
//										}) {
//											Text("Add to Playlist …")
//										}
//										Divider()
//										Button(action: {
//											print("Credits")
//										}) {
//											Text("Credits")
//										}
//										Button(action: {
//											print("Share")
//										}) {
//											Text("Share")
//										}
								}
								Divider()
							}
						}
						VStack(alignment: .trailing) {
							ForEach(0..<tracks!.count) { i in
								TrackRowBack(track: self.tracks![i])
									.onTapGesture(count: 2) {
										print("\(self.tracks![i].title)")
										self.player.add(tracks: self.tracks!, .now)
										self.player.play(atIndex: i)
									}
									.contextMenu {
										Button(action: {
											self.player.add(track: self.tracks![i], .now)
										}) {
											Text("Play now")
										}
										Button(action: {
											self.player.add(track: self.tracks![i], .next)
										}) {
											Text("Play next")
										}
										Button(action: {
											self.player.add(track: self.tracks![i], .last)
										}) {
											Text("Play last")
										}
//										Divider()
//										Button(action: {
//											print("Remove from Favorites")
//										}) {
//											Text("Remove from Favorites")
//										}
//										Button(action: {
//											print(" to Playlist …")
//										}) {
//											Text("Add to Playlist …")
//										}
//										Divider()
//										Button(action: {
//											print("Credits")
//										}) {
//											Text("Credits")
//										}
//										Button(action: {
//											print("Share")
//										}) {
//											Text("Share")
//										}
								}
								.frame(height: 30)
								Divider()
							}
						}
					}
				}
			} else {
				Text("Problems fetching favorite tracks")
				.font(.largeTitle)
				Spacer()
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
		Spacer()
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
