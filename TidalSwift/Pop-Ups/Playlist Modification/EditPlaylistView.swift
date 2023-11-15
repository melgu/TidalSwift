//
//  EditPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct EditPlaylistView: View {
	let session: Session
	
	@ObservedObject var playlistEditingValues: PlaylistEditingValues
	@ObservedObject var viewState: ViewState
	
	@State var playlistTitle: String = ""
	@State var playlistDescription: String = ""
	@State var showEmptyNameWarning: Bool = false
	
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
						Task {
							let success = await playlist.edit(title: playlistTitle, description: playlistDescription, session: session)
							if success {
								await playlist.removeOffline(session: session)
								playlistEditingValues.showEditModal = false
								viewState.refreshCurrentView()
							}
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
