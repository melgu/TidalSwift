//
//  RemoveFromPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

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
						print("Delete Index \(i) from \(playlist.title)")
						let success = playlist.removeTrack(atIndex: i, session: session)
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
