//
//  DeletePlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct DeletePlaylistView: View {
	let session: Session
	
	@ObservedObject var playlistEditingValues: PlaylistEditingValues
	@ObservedObject var viewState: ViewState
	
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
						Task {
							print("Delete \(playlist.title)")
							let success = await playlist.delete(session: session)
							if success {
								await playlist.removeOffline(session: session)
								await MainActor.run {
									playlistEditingValues.showDeleteModal = false
									viewState.refreshCurrentView()
								}
							}
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
