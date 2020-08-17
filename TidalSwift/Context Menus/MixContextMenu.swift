//
//  MixContextMenu.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct MixContextMenu: View {
	let mix: MixesItem
	let session: Session
	let player: Player
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		Group {
			Button {
				if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
					player.add(tracks: tracks, .now)
				}
			} label: {
				Text("Add Now")
			}
			Button {
				if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
					player.add(tracks: tracks, .next)
				}
			} label: {
				Text("Add Next")
			}
			Button {
				if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
					player.add(tracks: tracks, .last)
				}
			} label: {
				Text("Add Last")
			}
			Divider()
			Button {
				print("Add \(mix.title) to Playlist")
				if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
					playlistEditingValues.tracks = tracks
					playlistEditingValues.showAddTracksModal = true
				}
			} label: {
				Text("Add to Playlist …")
			}
			Divider()
			Button {
				print("Download")
				DispatchQueue.global(qos: .background).async {
					if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
						_ = session.helpers.download.download(tracks: tracks, parentFolder: mix.title)
					}
				}
			} label: {
				Text("Download")
			}
			Divider()
			Button {
				print("Image")
				let controller = ResizableWindowController(rootView: MixImage(mix: mix, highResolutionImages: true, session: session), width: 640, height: 640)
				controller.window?.title = mix.title
				controller.showWindow(nil)
			} label: {
				Text("Image")
			}
		}
	}
}
