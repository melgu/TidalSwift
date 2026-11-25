//
//  AddToPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "AddToPlaylistView")

struct AddToPlaylistView: View {
	let session: Session
	@Environment(Offline.self) private var offline
	
	@State private var playlists: [Playlist]? = nil
	@State private var loadingState: LoadingState = .loading
	
	let playlistEditingValues: PlaylistEditingValues
	let viewState: ViewState
	
	@State private var selectedPlaylist: String = "" // Playlist UUID
	@State private var newPlaylistName: String = ""
	@State private var newPlaylistDescription: String = ""
	@State private var showEmptyNameWarning: Bool = false
	
	init(session: Session, playlistEditingValues: PlaylistEditingValues, viewState: ViewState) {
		self.session = session
		self.playlistEditingValues = playlistEditingValues
		self.viewState = viewState
	}
	
	var body: some View {
		ScrollView {
			VStack {
				if let playlists = playlists {
					Text(itemCountString)
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
						.foregroundStyle(.secondary)
				}
				
				Text(showEmptyNameWarning ? "Playlist name can't be empty" : "")
					.foregroundStyle(.red)
				
				Text("Duplicates won't be added")
					.foregroundStyle(.secondary)
				
				HStack {
					Button {
						logger.debug("Cancel")
						playlistEditingValues.showAddTracksModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						Task {
							logger.debug("Add to \(selectedPlaylist)")
							guard !playlistEditingValues.items.isEmpty else {
								logger.error("Tried to add nothing to a playlist")
								return
							}
							var playlistId = selectedPlaylist
							if playlistId == "_newPlaylist" {
								guard !newPlaylistName.isEmpty else {
									logger.error("Playlist name can't be empty")
									showEmptyNameWarning = true
									return
								}
								guard let playlist = await session.playlistEditing.create(title: newPlaylistName, description: newPlaylistDescription) else {
									logger.error("Error creating Playlist")
									return
								}
								playlistId = playlist.uuid
								selectedPlaylist = playlistId
							}
							// Tidal takes video IDs here too
							let ids = playlistEditingValues.items.map(\.mediaId)
							let success = await session.playlistEditing.addTracks(ids, to: playlistId, duplicate: false)
							if success {
								if let playlist = await session.playlist(playlistId: playlistId) {
									offline.syncPlaylist(playlist)
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
	
	private var itemCountString: String {
		let items = playlistEditingValues.items
		let trackCount = items.count { $0.track != nil }
		let videoCount = items.count - trackCount
		var parts: [String] = []
		if trackCount > 0 || videoCount == 0 {
			parts.append(trackCount == 1 ? "1 track" : "\(trackCount) tracks")
		}
		if videoCount > 0 {
			parts.append(videoCount == 1 ? "1 video" : "\(videoCount) videos")
		}
		return parts.joined(separator: ", ")
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
