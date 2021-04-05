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
	@ObservedObject var sessionContainer: SessionContainer
	@ObservedObject var loginInfo: LoginInfo
	@ObservedObject var playlistEditingValues: PlaylistEditingValues
	@ObservedObject var viewState: ViewState
	@ObservedObject var sortingState: SortingState
	
	var body: some View {
		TopDetailView(session: sessionContainer.session, player: sessionContainer.player)
			.environmentObject(sessionContainer)
			.environmentObject(viewState)
			.environmentObject(sortingState)
			.environmentObject(playlistEditingValues)
			.environmentObject(sessionContainer.player.playbackInfo)
			.environmentObject(sessionContainer.player.queueInfo)
			.environmentObject(sessionContainer.session.helpers.downloadStatus)
			.background(EmptyView().sheet(isPresented: $loginInfo.showModal) {
				LoginView(loginInfo: loginInfo)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showAddTracksModal) {
				AddToPlaylistView(session: sessionContainer.session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showRemoveTracksModal) {
				RemoveFromPlaylistView(session: sessionContainer.session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showDeleteModal) {
				DeletePlaylistView(session: sessionContainer.session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showEditModal) {
				EditPlaylistView(session: sessionContainer.session, playlistEditingValues: playlistEditingValues, viewState: viewState)
			})
			.touchBar {
				TouchBarView(player: sessionContainer.player, playbackInfo: sessionContainer.player.playbackInfo)
			}
	}
}
