//
//  ContentView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ContentView: View {
	@ObservedObject var loginInfo: LoginInfo
	@ObservedObject var playlistEditingValues: PlaylistEditingValues
	@ObservedObject var viewState: ViewState
	@ObservedObject var sortingState: SortingState
	
	let session: Session
	let player: Player
	
	var body: some View {
		TopDetailView(session: session, player: player)
			.environmentObject(viewState)
			.environmentObject(sortingState)
			.environmentObject(playlistEditingValues)
			.environmentObject(player.playbackInfo)
			.environmentObject(player.queueInfo)
			.environmentObject(session.helpers.downloadStatus)
			.background(EmptyView().sheet(isPresented: $loginInfo.showModal) {
				LoginView(loginInfo: loginInfo, viewState: viewState, session: session, player: player)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showAddTracksModal) {
				AddToPlaylistView(session: session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showRemoveTracksModal) {
				RemoveFromPlaylistView(session: session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showDeleteModal) {
				DeletePlaylistView(session: session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showEditModal) {
				EditPlaylistView(session: session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.touchBar {
				TouchBarView(player: player, playbackInfo: player.playbackInfo)
			}
			.onAppear {
				DispatchQueue.global().async {
					let success = session.populateVariablesForAccessToken()
					if !success {
						DispatchQueue.main.async {
							loginInfo.showModal = true
						}
					}
				}
			}
	}
}
