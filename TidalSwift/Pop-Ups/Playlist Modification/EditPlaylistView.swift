//
//  EditPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "EditPlaylistView")

struct EditPlaylistView: View {
	let session: Session
	@Environment(Offline.self) private var offline
	
	let playlistEditingValues: PlaylistEditingValues
	let viewState: ViewState
	
	@State private var playlistTitle: String = ""
	@State private var playlistDescription: String = ""
	@State private var showEmptyNameWarning: Bool = false
	@State private var isOffline: Bool = false
	
	var body: some View {
		VStack {
			if let playlist = playlistEditingValues.playlist {
				Text("Edit \(playlist.title)")
				TextField("New Playlist", text: $playlistTitle)
					.onAppear {
						playlistTitle = playlist.title
					}
				TextField("Optional Playlist Description", text: $playlistDescription)
					.onAppear {
						playlistDescription = playlist.description ?? ""
					}
				if isOffline {
					Text("This playlist is saved offline, but won't anymore if renamed. You have to to add it to Offline items again manually, if you so desire.")
						.foregroundColor(.secondary)
				}
				
				HStack {
					Button {
						logger.debug("Cancel")
						playlistEditingValues.showEditModal = false
					} label: {
						Text("Cancel")
					}
					Button {
						logger.debug("Rename \(playlist.title)")
						Task {
							let success = await playlist.edit(title: playlistTitle, description: playlistDescription, session: session)
							if success {
								await offline.remove(playlist: playlist)
								playlistEditingValues.showEditModal = false
								viewState.refreshCurrentView()
							}
						}
					} label: {
						Text("Rename")
					}
				}
				.task(id: playlist.uuid) {
					isOffline = await offline.isPlaylistOffline(playlist: playlist)
				}
			} else {
				Text("Missing Playlist")
			}
		}
		.padding()
	}
}
