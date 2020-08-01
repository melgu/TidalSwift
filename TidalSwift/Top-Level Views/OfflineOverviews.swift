//
//  OfflineOverviews.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.01.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct OfflinePlaylistsView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Offline Playlists")
						.font(.largeTitle)
					Spacer()
					Picker(selection: $sortingState.offlinePlaylistSorting, label: Spacer(minLength: 0)) {
//						Text("Added").tag(PlaylistSorting.dateAdded)
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
					ReverseButton(reversed: $sortingState.offlinePlaylistReversed)
				}
				if let playlists = viewState.stack.last?.playlists {
					HStack {
						Text("\(playlists.count) \(playlists.count == 1 ? "Playlist" : "Playlists")")
						Spacer()
					}
					PlaylistGrid(playlists: playlists.sortedPlaylists(by: sortingState.offlinePlaylistSorting).reversed(sortingState.offlinePlaylistReversed), session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding(.horizontal)
		}
	}
}

struct OfflineAlbumsView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Offline Albums")
						.font(.largeTitle)
					Spacer()
					Picker(selection: $sortingState.offlineAlbumSorting, label: Spacer(minLength: 0)) {
//						Text("Added").tag(AlbumSorting.dateAdded)
						Text("Title").tag(AlbumSorting.title)
						Text("Artists").tag(AlbumSorting.artists)
						Text("Release Date").tag(AlbumSorting.releaseDate)
						Text("Duration").tag(AlbumSorting.duration)
						Text("Popularity").tag(AlbumSorting.popularity)
					}
					.pickerStyle(SegmentedPickerStyle())
					.frame(width: PICKERWIDTH)
					ReverseButton(reversed: $sortingState.offlineAlbumReversed)
				}
				if let albums = viewState.stack.last?.albums {
					HStack {
						Text("\(albums.count) \(albums.count == 1 ? "Album" : "Albums")")
						Spacer()
					}
					
					AlbumGrid(albums: albums.sortedAlbums(by: sortingState.offlineAlbumSorting).reversed(sortingState.offlineAlbumReversed), showArtists: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding(.horizontal)
		}
	}
}

struct OfflineTracksView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack {
					HStack {
						Text("Offline Tracks")
							.font(.largeTitle)
						Spacer()
						Picker(selection: $sortingState.offlineTrackSorting, label: Spacer(minLength: 0)) {
//							Text("Added").tag(TrackSorting.dateAdded)
							Text("Title").tag(TrackSorting.title)
							Text("Artists").tag(TrackSorting.artists)
							Text("Album").tag(TrackSorting.album)
							Text("Release Date").tag(TrackSorting.albumReleaseDate)
//							Text("Duration").tag(TrackSorting.duration)
							Text("Popularity").tag(TrackSorting.popularity)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
						ReverseButton(reversed: $sortingState.offlineTrackReversed)
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
					TrackList(wrappedTracks: tracks.sortedTracks(by: sortingState.offlineTrackSorting).reversed(sortingState.offlineTrackReversed).wrapped(), showCover: true, showAlbumTrackNumber: false, showArtist: true, showAlbum: true, playlist: nil, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
		}
	}
}
