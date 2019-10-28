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
	@Published var tracksToAdd: [Track] = []
	
	@Published var showDeleteModal: Bool = false
	@Published var showEditModal: Bool = false
	@Published var playlistToModify: Playlist?
}

struct AddToPlaylistView: View {
	let session: Session
	let playlists: [Playlist]?
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
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
				if playlists != nil {
					Text("\(playlistEditingValues.tracksToAdd.count) \(playlistEditingValues.tracksToAdd.count > 1 ? "tracks" : "track")")
					Picker(selection: $selectedPlaylist, label: Spacer(minLength: 0)) {
						ForEach(playlists!) { playlist in
							Text(playlist.title).tag(playlist.uuid)
						}
						VStack {
							TextField("New Playlist", text: $newPlaylistName)
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
					Button(action: {
						print("Cancel")
						self.playlistEditingValues.showAddTracksModal = false
					}) {
						Text("Cancel")
					}
					Button(action: {
						print("Add to \(self.selectedPlaylist)")
						guard !self.playlistEditingValues.tracksToAdd.isEmpty else {
							print("Tried to add zero tracks to a playlist")
							return
						}
						if self.selectedPlaylist == "_newPlaylist" {
							guard !self.newPlaylistName.isEmpty else {
								print("Playlist name can't be empty")
								self.showEmptyNameWarning = true
								return
							}
							guard let playlist = self.session.createPlaylist(title: self.newPlaylistName, description: self.newPlaylistDescription) else {
								print("Error creating Playlist")
								return
							}
							self.selectedPlaylist = playlist.uuid
						}
						let ids = self.playlistEditingValues.tracksToAdd.map { $0.id }
						let success = self.session.addTracks(ids, to: self.selectedPlaylist, duplicate: false)
						if success {
							self.playlistEditingValues.showAddTracksModal = false
						}
					}) {
						Text("Add")
					}
					.disabled(selectedPlaylist == "")
				}
			}
			.padding()
		}
	}
}

struct DeletePlaylist: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		VStack {
			Text("Delete \(self.playlistEditingValues.playlistToModify!.title)?")
			
			HStack {
				Button(action: {
					print("Cancel")
					self.playlistEditingValues.showDeleteModal = false
				}) {
					Text("Cancel")
				}
				Button(action: {
					print("Delete \(self.playlistEditingValues.playlistToModify!.title)")
					let success = self.session.deletePlaylist(playlistId: self.playlistEditingValues.playlistToModify!.uuid)
					if success {
						self.playlistEditingValues.showDeleteModal = false
					}
				}) {
					Text("Delete")
				}
			}
		}
		.padding()
	}
}

struct EditPlaylist: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	@State var playlistName: String = ""
	@State var playlistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
	var body: some View {
		VStack {
			Text("Edit \(self.playlistEditingValues.playlistToModify!.title)")
			TextField("New Playlist", text: $playlistName)
				.onAppear {
					self.playlistName = self.playlistEditingValues.playlistToModify!.title
			}
			TextField("Optional Playlist Description", text: $playlistDescription)
				.onAppear {
					self.playlistDescription = self.playlistEditingValues.playlistToModify!.description ?? ""
			}
			HStack {
				Button(action: {
					print("Cancel")
					self.playlistEditingValues.showEditModal = false
				}) {
					Text("Cancel")
				}
				Button(action: {
					print("Rename \(self.playlistEditingValues.playlistToModify!.title)")
					let success = self.session.editPlaylist(playlistId: self.playlistEditingValues.playlistToModify!.uuid,
															title: self.playlistName, description: self.playlistDescription)
					if success {
						self.playlistEditingValues.showEditModal = false
					}
				}) {
					Text("Rename")
				}
			}
		}
		.padding()
	}
}
