//
//  AddToPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 25.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

final class PlaylistEditingValues: ObservableObject {
	@Published var showAddTracksModal: Bool = false
	@Published var tracks: [Track] = []
	
	@Published var showRemoveTracksModal: Bool = false
	@Published var indexToRemove: Int?
	
	@Published var showDeleteModal: Bool = false
	@Published var showEditModal: Bool = false
	@Published var playlist: Playlist?
}

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
							guard let playlist = session.createPlaylist(title: newPlaylistName, description: newPlaylistDescription) else {
								print("Error creating Playlist")
								return
							}
							selectedPlaylist = playlist.uuid
						}
						let ids = playlistEditingValues.tracks.map { $0.id }
						let success = session.addTracks(ids, to: selectedPlaylist, duplicate: false)
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

struct RemoveFromPlaylistView: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			if let playlist = playlistEditingValues.playlist {
				Text("Delete \(playlistEditingValues.tracks[0].title) from \(playlist.title)?")
				
				HStack {
					Button {
						print("Cancel")
						playlistEditingValues.showRemoveTracksModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						let i = playlistEditingValues.indexToRemove!
						let uuid = playlist.uuid
						print("Delete Index \(i) from \(playlist.title)")
						let success = session.removeTrack(index: i, from: uuid)
						if success {
							session.helpers.offline.syncPlaylist(playlist)
							viewState.refreshCurrentView()
							playlistEditingValues.showRemoveTracksModal = false
						}
					} label: {
						Text("Delete")
					}
				}
			} else {
				Text("Missing Playlist")
			}
		}
		.padding()
	}
}


struct DeletePlaylist: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			if let playlist = playlistEditingValues.playlist {
				Text("Delete \(playlist.title)?")
				
				HStack {
					Button {
						print("Cancel")
						playlistEditingValues.showDeleteModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						print("Delete \(playlist.title)")
						let success = session.deletePlaylist(playlistId: playlist.uuid)
						if success {
							playlist.removeOffline(session: session)
							playlistEditingValues.showDeleteModal = false
							viewState.refreshCurrentView()
						}
					} label: {
						Text("Delete")
					}
				}
			} else {
				Text("Missing Playlist")
			}
		}
		.padding()
	}
}

struct EditPlaylist: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	@State var playlistName: String = ""
	@State var playlistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
	var body: some View {
		VStack {
			if let playlist = playlistEditingValues.playlist {
				Text("Edit \(playlist.title)")
				TextField("New Playlist", text: $playlistName)
					.onAppear {
						playlistName = playlist.title
					}
				TextField("Optional Playlist Description", text: $playlistDescription)
					.onAppear {
						playlistDescription = playlist.description ?? ""
					}
				if playlist.isOffline(session: session) {
					Text("This playlist is saved offline, but won't anymore if renamed. You have to to add it to Offline items again manually, if you so desire.")
						.foregroundColor(.secondary)
				}
				
				HStack {
					Button {
						print("Cancel")
						playlistEditingValues.showEditModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						print("Rename \(playlist.title)")
						let success = session.editPlaylist(playlistId: playlist.uuid,
																title: playlistName, description: playlistDescription)
						if success {
							playlist.removeOffline(session: session)
							playlistEditingValues.showEditModal = false
							viewState.refreshCurrentView()
						}
					} label: {
						Text("Rename")
					}
				}
			} else {
				Text("Missing Playlist")
			}
		}
		.padding()
	}
}
