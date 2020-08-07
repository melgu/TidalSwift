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
	let playlists: [Playlist]?
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	@State var selectedPlaylist: String = "" // Playlist UUID
	@State var newPlaylistName: String = ""
	@State var newPlaylistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
	init(session: Session) {
		self.session = session
		self.playlists = session.favorites?.userPlaylists()
	}
	
	var body: some View {
		ScrollView {
			VStack {
				if let playlists = playlists {
					Text("\(playlistEditingValues.tracks.count) \(playlistEditingValues.tracks.count > 1 ? "tracks" : "track")")
					Picker(selection: $selectedPlaylist, label: Spacer(minLength: 0)) {
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
						}.tag("_newPlaylist")
					}
					.pickerStyle(RadioGroupPickerStyle())
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
						print("Add to \(selectedPlaylist)")
						guard !playlistEditingValues.tracks.isEmpty else {
							print("Tried to add zero tracks to a playlist")
							return
						}
						if selectedPlaylist == "_newPlaylist" {
							guard !newPlaylistName.isEmpty else {
								print("Playlist name can't be empty")
								showEmptyNameWarning = true
								return
							}
							guard let playlist = session.playlistEditing.create(title: newPlaylistName, description: newPlaylistDescription) else {
								print("Error creating Playlist")
								return
							}
							selectedPlaylist = playlist.uuid
						}
						let ids = playlistEditingValues.tracks.map { $0.id }
						let success = session.playlistEditing.addTracks(ids, to: selectedPlaylist, duplicate: false)
						if success {
							if let playlist = session.getPlaylist(playlistId: selectedPlaylist) {
								session.helpers.offline.syncPlaylist(playlist)
								viewState.refreshCurrentView()
							}
							playlistEditingValues.showAddTracksModal = false
						}
					} label: {
						Text("Add")
					}
					.disabled(selectedPlaylist == "")
				}
			}
			.padding()
		}
	}
}
