//
//  AddToPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AddToPlaylistView: View {
	let session: Session
	
	@State private var playlists: [Playlist]? = nil
	@State private var loadingState: LoadingState = .loading
	
	@ObservedObject var playlistEditingValues: PlaylistEditingValues
	@ObservedObject var viewState: ViewState
	
	@State var selectedPlaylist: String = "" // Playlist UUID
	@State var newPlaylistName: String = ""
	@State var newPlaylistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
	init(session: Session, playlistEditingValues: PlaylistEditingValues, viewState: ViewState) {
		self.session = session
		self.playlistEditingValues = playlistEditingValues
		self.viewState = viewState
	}
	
	var body: some View {
		ScrollView {
			VStack {
				if let playlists = playlists {
					Text("\(playlistEditingValues.tracks.count) \(playlistEditingValues.tracks.count > 1 ? "tracks" : "track")")
					Picker("Playlist", selection: $selectedPlaylist) {
						ForEach(playlists) { playlist in
							Text(playlist.title).tag(playlist.uuid)
						}
						VStack {
							TextField("New Playlist", text: $newPlaylistName, onEditingChanged: { _ in
								selectedPlaylist = "_newPlaylist"
							})
							if !newPlaylistName.isEmpty {
								TextField("Optional Playlist Description", text: $newPlaylistDescription)
							}
						}
						.frame(minWidth: 200)
						.tag("_newPlaylist")
					}
					.labelsHidden()
					#if canImport(AppKit)
					.pickerStyle(RadioGroupPickerStyle())
					#else
					.pickerStyle(.automatic)
					#endif
				} else if loadingState == .loading {
					ProgressView()
				} else {
					Text("Couldn't load playlists")
						.foregroundColor(.secondary)
				}
				
				Text(showEmptyNameWarning ? "Playlist name can't be empty" : "")
					.foregroundColor(.red)
				
				Text("Duplicate tracks won't be added")
					.foregroundColor(.secondary)
				
				HStack {
					Button {
						print("Cancel")
						playlistEditingValues.showAddTracksModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						Task {
							print("Add to \(selectedPlaylist)")
							guard !playlistEditingValues.tracks.isEmpty else {
								print("Tried to add zero tracks to a playlist")
								return
							}
							var playlistId = selectedPlaylist
							if playlistId == "_newPlaylist" {
								guard !newPlaylistName.isEmpty else {
									print("Playlist name can't be empty")
									showEmptyNameWarning = true
									return
								}
								guard let playlist = await session.playlistEditing.create(title: newPlaylistName, description: newPlaylistDescription) else {
									print("Error creating Playlist")
									return
								}
								playlistId = playlist.uuid
								selectedPlaylist = playlistId
							}
							let ids = playlistEditingValues.tracks.map { $0.id }
							let success = await session.playlistEditing.addTracks(ids, to: playlistId, duplicate: false)
							if success {
								if let playlist = await session.playlist(playlistId: playlistId) {
									session.helpers.offline.syncPlaylist(playlist)
									viewState.refreshCurrentView()
									playlistEditingValues.showAddTracksModal = false
								} else {
									playlistEditingValues.showAddTracksModal = false
								}
							}
						}
					} label: {
						Text("Add")
					}
					.disabled(selectedPlaylist == "")
				}
			}
			.padding()
		}
		// Playlists load after the sheet is presented, so it can't size itself to them
		.frame(minWidth: 300, idealWidth: 400, minHeight: 300, idealHeight: 500)
		.task {
			await loadPlaylistsIfNeeded()
		}
	}
	
	private func loadPlaylistsIfNeeded() async {
		guard playlists == nil else { return }
		loadingState = .loading
		playlists = await session.favorites?.userPlaylists()
		loadingState = playlists == nil ? .error : .successful
		if selectedPlaylist.isEmpty {
			selectedPlaylist = playlists?.first?.uuid ?? ""
		}
	}
}
