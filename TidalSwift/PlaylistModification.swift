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
	@Published var indexToRemove: Int? = nil
	
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
				if playlists != nil {
					Text("\(playlistEditingValues.tracks.count) \(playlistEditingValues.tracks.count > 1 ? "tracks" : "track")")
					Picker(selection: $selectedPlaylist, label: Spacer(minLength: 0)) {
						ForEach(playlists!) { playlist in
							Text(playlist.title).tag(playlist.uuid)
						}
						VStack {
							TextField("New Playlist", text: $newPlaylistName, onEditingChanged: { _ in
								self.selectedPlaylist = "_newPlaylist"
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
					Button(action: {
						print("Cancel")
						self.playlistEditingValues.showAddTracksModal = false
					}) {
						Text("Cancel")
					}
					Button(action: {
						print("Add to \(self.selectedPlaylist)")
						guard !self.playlistEditingValues.tracks.isEmpty else {
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
						let ids = self.playlistEditingValues.tracks.map { $0.id }
						let success = self.session.addTracks(ids, to: self.selectedPlaylist, duplicate: false)
						if success {
							if let playlist = self.session.getPlaylist(playlistId: self.selectedPlaylist) {
								DispatchQueue.global(qos: .background).async {
									self.session.helpers.offline.syncPlaylist(playlist)
									DispatchQueue.main.async {
										self.viewState.refreshCurrentView()
									}
								}
							}
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

struct RemoveFromPlaylistView: View {
	let session: Session
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			Text("Delete \(self.playlistEditingValues.tracks[0].title) from \(playlistEditingValues.playlist!.title)?")
			
			HStack {
				Button(action: {
					print("Cancel")
					self.playlistEditingValues.showRemoveTracksModal = false
				}) {
					Text("Cancel")
				}
				Button(action: {
					let i = self.playlistEditingValues.indexToRemove!
					let uuid = self.playlistEditingValues.playlist!.uuid
					print("Delete Index \(i) from \(self.playlistEditingValues.playlist!.title)")
					let success = self.session.removeTrack(index: i, from: uuid)
					if success {
						DispatchQueue.global(qos: .background).async {
							self.session.helpers.offline.syncPlaylist(self.playlistEditingValues.playlist!)
							DispatchQueue.main.async {
								self.viewState.refreshCurrentView()
							}
						}
						self.playlistEditingValues.showRemoveTracksModal = false
					}
				}) {
					Text("Delete")
				}
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
			Text("Delete \(self.playlistEditingValues.playlist!.title)?")
			
			HStack {
				Button(action: {
					print("Cancel")
					self.playlistEditingValues.showDeleteModal = false
				}) {
					Text("Cancel")
				}
				Button(action: {
					print("Delete \(self.playlistEditingValues.playlist!.title)")
					let success = self.session.deletePlaylist(playlistId: self.playlistEditingValues.playlist!.uuid)
					if success {
						self.session.helpers.offline.remove(playlist: self.playlistEditingValues.playlist!)
						self.playlistEditingValues.showDeleteModal = false
						self.viewState.refreshCurrentView()
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
	@EnvironmentObject var viewState: ViewState
	
	@State var playlistName: String = ""
	@State var playlistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
	var body: some View {
		VStack {
			Text("Edit \(self.playlistEditingValues.playlist!.title)")
			TextField("New Playlist", text: $playlistName)
				.onAppear {
					self.playlistName = self.playlistEditingValues.playlist!.title
			}
			TextField("Optional Playlist Description", text: $playlistDescription)
				.onAppear {
					self.playlistDescription = self.playlistEditingValues.playlist!.description ?? ""
			}
			if session.helpers.offline.isPlaylistOffline(playlist: playlistEditingValues.playlist!) {
				Text("This playlist is saved offline, but won't anymore if renamed. You have to to add it to Offline items again manually, if you so desire.")
					.foregroundColor(.secondary)
			}
			
			HStack {
				Button(action: {
					print("Cancel")
					self.playlistEditingValues.showEditModal = false
				}) {
					Text("Cancel")
				}
				Button(action: {
					print("Rename \(self.playlistEditingValues.playlist!.title)")
					let success = self.session.editPlaylist(playlistId: self.playlistEditingValues.playlist!.uuid,
															title: self.playlistName, description: self.playlistDescription)
					if success {
						self.session.helpers.offline.remove(playlist: self.playlistEditingValues.playlist!)
						self.playlistEditingValues.showEditModal = false
						self.viewState.refreshCurrentView()
					}
				}) {
					Text("Rename")
				}
			}
		}
		.padding()
	}
}
