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
	
	@State var playlists: [Playlist]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Playlists")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if playlists != nil {
				PlaylistGrid(playlists: playlists!, session: session, player: player)
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite playlists")
					.font(.largeTitle)
			}
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let favorites = self.session.favorites else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			guard let favT = favorites.playlists() else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = favoritePlaylists2Playlists(favT)
			DispatchQueue.main.async {
				self.playlists = t
				self.loadingState = .successful
			}
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
	
	@State var albums: [Album]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Albums")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if albums != nil {
				AlbumGrid(albums: albums!, showArtists: true, session: session, player: player)
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite albums")
					.font(.largeTitle)
			}
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let favorites = self.session.favorites else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			guard let favT = favorites.albums(order: .dateAdded, orderDirection: .descending) else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = favoriteAlbums2Albums(favT)
			DispatchQueue.main.async {
				self.albums = t
				self.loadingState = .successful
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
	
	@State var tracks: [Track]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Tracks")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if tracks != nil {
				ScrollView {
					TrackList(tracks: tracks!, showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite tracks")
					.font(.largeTitle)
				Spacer()
			}
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let favorites = self.session.favorites else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			guard let favT = favorites.tracks(order: .dateAdded, orderDirection: .descending) else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = favoriteTracks2Tracks(favT)
			DispatchQueue.main.async {
				self.tracks = t
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
	
	@State var videos: [Video]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Videos")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if videos != nil {
				VideoGrid(videos: videos!,
						  showArtists: true, session: session, player: player)
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite videos")
					.font(.largeTitle)
			}
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let favorites = self.session.favorites else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			guard let favT = favorites.videos(order: .dateAdded, orderDirection: .descending) else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = favoriteVideos2Videos(favT)
			DispatchQueue.main.async {
				self.videos = t
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
	
	@State var artists: [Artist]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Artists")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if artists != nil {
				ArtistGrid(artists: artists!, session: session, player: player)
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite artists")
					.font(.largeTitle)
			}
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
		
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let favorites = self.session.favorites else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			guard let favT = favorites.artists() else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = favoriteArtists2Artists(favT)
			DispatchQueue.main.async {
				self.artists = t
			}
		}
	}
}

func favoriteArtists2Artists(_ favoriteArtists: [FavoriteArtist]) -> [Artist] {
	favoriteArtists.map { $0.item }
}
