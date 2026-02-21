//
//  Favorites.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

let PICKERWIDTH: CGFloat = 580

struct ReverseButton: View {
	@Binding var reversed: Bool
	
	var body: some View {
		Button {
			reversed.toggle()
		} label: {
			if reversed {
				Text("∨")
//				Image(systemName: "arrow.down")
			} else {
				Text("∧")
//				Image(systemName: "arrow.up")
			}
		}
	}
}

struct FavoritePlaylists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Playlists")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
					LoadingSpinner()
					Picker(selection: $sortingState.favoritePlaylistSorting, label: Spacer(minLength: 0)) {
						Text("Added").tag(PlaylistSorting.dateAdded)
						Text("Title").tag(PlaylistSorting.title)
						Text("Last Updated").tag(PlaylistSorting.lastUpdated)
						Text("Created").tag(PlaylistSorting.created)
//						Text("Track Number").tag(PlaylistSorting.numberOfTracks)
//						Text("Duration").tag(PlaylistSorting.duration)
						Text("Type").tag(PlaylistSorting.type)
//						Text("Creator").tag(PlaylistSorting.creator)
					}
					.pickerStyle(SegmentedPickerStyle())
					.frame(width: PICKERWIDTH)
					ReverseButton(reversed: $sortingState.favoritePlaylistReversed)
				}
				if let playlists = viewState.stack.last?.playlists {
					HStack {
						Text("\(playlists.count) \(playlists.count == 1 ? "Playlist" : "Playlists")")
						Spacer()
					}
					PlaylistGrid(playlists: playlists.sortedPlaylists(by: sortingState.favoritePlaylistSorting).reversed(sortingState.favoritePlaylistReversed), session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteAlbums: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Albums")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
					LoadingSpinner()
					Picker(selection: $sortingState.favoriteAlbumSorting, label: Spacer(minLength: 0)) {
						Text("Added").tag(AlbumSorting.dateAdded)
						Text("Title").tag(AlbumSorting.title)
						Text("Artists").tag(AlbumSorting.artists)
						Text("Release Date").tag(AlbumSorting.releaseDate)
						Text("Duration").tag(AlbumSorting.duration)
						Text("Popularity").tag(AlbumSorting.popularity)
					}
					.pickerStyle(SegmentedPickerStyle())
					.frame(width: PICKERWIDTH)
					ReverseButton(reversed: $sortingState.favoriteAlbumReversed)
				}
				if let albums = viewState.stack.last?.albums {
					HStack {
						Text("\(albums.count) \(albums.count == 1 ? "Album" : "Albums")")
						Spacer()
					}
					AlbumGrid(albums: albums.sortedAlbums(by: sortingState.favoriteAlbumSorting).reversed(sortingState.favoriteAlbumReversed), showArtists: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	@AppStorage("SaveFavoritesOffline") public var saveFavoritesOffline = false
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack {
					HStack {
						Text("Favorite Tracks")
							.font(.largeTitle)
							.lineLimit(1)
						Spacer()
						LoadingSpinner()
						if saveFavoritesOffline {
							Image(systemName: "cloud.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 30)
								.onTapGesture {
									print("Remove from Offline")
									saveFavoritesOffline = false
									session.helpers.offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
						} else {
							Image(systemName: "cloud")
								.resizable()
								.scaledToFit()
								.frame(width: 30)
								.onTapGesture {
									print("Add to Offline")
									saveFavoritesOffline = true
									session.helpers.offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
						}
						Picker(selection: $sortingState.favoriteTrackSorting, label: Spacer(minLength: 0)) {
							Text("Added").tag(TrackSorting.dateAdded)
							Text("Title").tag(TrackSorting.title)
							Text("Artists").tag(TrackSorting.artists)
							Text("Album").tag(TrackSorting.album)
							Text("Release Date").tag(TrackSorting.albumReleaseDate)
//							Text("Duration").tag(TrackSorting.duration)
							Text("Popularity").tag(TrackSorting.popularity)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
						ReverseButton(reversed: $sortingState.favoriteTrackReversed)
					}
					if let tracks = viewState.stack.last?.tracks {
						HStack {
							Text("\(tracks.count) \(tracks.count == 1 ? "Track" : "Tracks")")
							Spacer()
						}
					}
				}
				.padding(.horizontal)
				
				if let tracks = viewState.stack.last?.tracks {
					TrackList(wrappedTracks: tracks.sortedTracks(by: sortingState.favoriteTrackSorting).reversed(sortingState.favoriteTrackReversed).wrapped(),
							  showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding(.top)
		}
	}
}

struct FavoriteVideos: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Videos")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
					LoadingSpinner()
					Picker(selection: $sortingState.favoriteVideoSorting, label: Spacer(minLength: 0)) {
						Text("Added").tag(VideoSorting.dateAdded)
						Text("Title").tag(VideoSorting.title)
						Text("Artists").tag(VideoSorting.artists)
						Text("Release Date").tag(VideoSorting.releaseDate)
						Text("Duration").tag(VideoSorting.duration)
						Text("Popularity").tag(VideoSorting.popularity)
					}
					.pickerStyle(SegmentedPickerStyle())
					.frame(width: PICKERWIDTH)
					ReverseButton(reversed: $sortingState.favoriteVideoReversed)
				}
				if let videos = viewState.stack.last?.videos {
					HStack {
						Text("\(videos.count) \(videos.count == 1 ? "Video" : "Videos")")
						Spacer()
					}
					VideoGrid(videos: videos.sortedVideos(by: sortingState.favoriteVideoSorting).reversed(sortingState.favoriteVideoReversed),
							  showArtists: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteArtists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack {
					HStack {
						Text("Favorite Artists")
							.font(.largeTitle)
							.lineLimit(1)
						Spacer()
						LoadingSpinner()
						Picker(selection: $sortingState.favoriteArtistSorting, label: Spacer(minLength: 0)) {
							Text("Added").tag(ArtistSorting.dateAdded)
							Text("Name").tag(ArtistSorting.name)
							Text("Popularity").tag(ArtistSorting.popularity)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
						ReverseButton(reversed: $sortingState.favoriteArtistReversed)
					}
					if let artists = viewState.stack.last?.artists {
						HStack {
							Text("\(artists.count) \(artists.count == 1 ? "Artist" : "Artists")")
							Spacer()
						}
						ArtistGrid(artists: artists.sortedArtists(by: sortingState.favoriteArtistSorting).reversed(sortingState.favoriteArtistReversed), session: session, player: player)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
