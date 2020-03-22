//
//  Favorites.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

let PICKERWIDTH: CGFloat = 450

struct ReverseButton: View {
	@Binding var reversed: Bool
	
	var body: some View {
		Button(action: {
			self.reversed.toggle()
		}) {
			if reversed {
				Text("∨")
//				Image("arrow.down")
			} else {
				Text("∧")
//				Image("arrow.up")
			}
		}
	}
}

struct FavoritePlaylists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: FavoritesSortingState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Playlists")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				Picker(selection: $sortingState.playlistSorting, label: Spacer(minLength: 0)) {
					Text("Added").tag(PlaylistSorting.dateAdded)
					Text("Title").tag(PlaylistSorting.title)
					Text("Last Updated").tag(PlaylistSorting.lastUpdated)
					Text("Created").tag(PlaylistSorting.created)
//					Text("Track Number").tag(PlaylistSorting.numberOfTracks)
//					Text("Duration").tag(PlaylistSorting.duration)
					Text("Type").tag(PlaylistSorting.type)
//					Text("Creator").tag(PlaylistSorting.creator)
				}
				.pickerStyle(SegmentedPickerStyle())
				.frame(width: PICKERWIDTH)
				ReverseButton(reversed: $sortingState.playlistReversed)
			}
			.padding(.horizontal)
			
			if viewState.stack.last?.playlists != nil {
				PlaylistGrid(playlists: viewState.stack.last!.playlists!.sortedPlaylists(by: sortingState.playlistSorting).reversed(sortingState.playlistReversed), session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

struct FavoriteAlbums: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: FavoritesSortingState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Albums")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				Picker(selection: $sortingState.albumSorting, label: Spacer(minLength: 0)) {
					Text("Added").tag(AlbumSorting.dateAdded)
					Text("Title").tag(AlbumSorting.title)
					Text("Artists").tag(AlbumSorting.artists)
					Text("Release Date").tag(AlbumSorting.releaseDate)
					Text("Duration").tag(AlbumSorting.duration)
					Text("Popularity").tag(AlbumSorting.popularity)
				}
				.pickerStyle(SegmentedPickerStyle())
				.frame(width: PICKERWIDTH)
				ReverseButton(reversed: $sortingState.albumReversed)
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.albums != nil {
				AlbumGrid(albums: viewState.stack.last!.albums!.sortedAlbums(by: sortingState.albumSorting).reversed(sortingState.albumReversed), showArtists: true, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: FavoritesSortingState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Tracks")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				if session.helpers.offline.saveFavoritesOffline {
					Image("cloud.fill-big")
						.primaryIconColor()
						.onTapGesture {
							print("Remove from Offline")
							self.session.helpers.offline.saveFavoritesOffline = false
							self.session.helpers.offline.asyncSyncFavoriteTracks()
							self.viewState.refreshCurrentView()
					}
				} else {
					Image("cloud-big")
						.primaryIconColor()
						.onTapGesture {
							print("Add to Offline")
							self.session.helpers.offline.saveFavoritesOffline = true
							self.session.helpers.offline.asyncSyncFavoriteTracks()
							self.viewState.refreshCurrentView()
					}
				}
				Picker(selection: $sortingState.trackSorting, label: Spacer(minLength: 0)) {
					Text("Added").tag(TrackSorting.dateAdded)
					Text("Title").tag(TrackSorting.title)
					Text("Artists").tag(TrackSorting.artists)
					Text("Album").tag(TrackSorting.album)
					Text("Release Date").tag(TrackSorting.albumReleaseDate)
//					Text("Duration").tag(TrackSorting.duration)
					Text("Popularity").tag(TrackSorting.popularity)
				}
				.pickerStyle(SegmentedPickerStyle())
				.frame(width: PICKERWIDTH)
				ReverseButton(reversed: $sortingState.trackReversed)
			}
			.padding(.horizontal)
			
			if viewState.stack.last?.tracks != nil {
				ScrollView {
					TrackList(wrappedTracks: viewState.stack.last!.tracks!.sortedTracks(by: sortingState.trackSorting).reversed(sortingState.trackReversed).wrapped(),
							  showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
			}
			Spacer(minLength: 0)
		}
	}
}

struct FavoriteVideos: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: FavoritesSortingState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Videos")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				Picker(selection: $sortingState.videoSorting, label: Spacer(minLength: 0)) {
					Text("Added").tag(VideoSorting.dateAdded)
					Text("Title").tag(VideoSorting.title)
					Text("Artists").tag(VideoSorting.artists)
					Text("Release Date").tag(VideoSorting.releaseDate)
					Text("Duration").tag(VideoSorting.duration)
					Text("Popularity").tag(VideoSorting.popularity)
				}
				.pickerStyle(SegmentedPickerStyle())
				.frame(width: PICKERWIDTH)
				ReverseButton(reversed: $sortingState.videoReversed)
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.videos != nil {
				VideoGrid(videos: viewState.stack.last!.videos!.sortedVideos(by: sortingState.videoSorting).reversed(sortingState.videoReversed),
						  showArtists: true, session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}

struct FavoriteArtists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: FavoritesSortingState
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Favorite Artists")
					.font(.largeTitle)
				Spacer()
				LoadingSpinner()
				Picker(selection: $sortingState.artistSorting, label: Spacer(minLength: 0)) {
					Text("Added").tag(ArtistSorting.dateAdded)
					Text("Name").tag(ArtistSorting.name)
					Text("Popularity").tag(ArtistSorting.popularity)
				}
				.pickerStyle(SegmentedPickerStyle())
				.frame(width: PICKERWIDTH)
				ReverseButton(reversed: $sortingState.artistReversed)
			}
			.padding(.horizontal)
			
			if viewState.stack.last!.artists != nil {
				ArtistGrid(artists: viewState.stack.last!.artists!.sortedArtists(by: sortingState.artistSorting).reversed(sortingState.artistReversed), session: session, player: player)
			}
			Spacer(minLength: 0)
		}
	}
}
