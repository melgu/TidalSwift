//
//  ContentView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct ContentView: View {
	@EnvironmentObject var sc: SessionContainer
	@EnvironmentObject var loginInfo: LoginInfo
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		MasterDetailView(session: sc.session, player: sc.player)
			.environmentObject(sc.player.playbackInfo)
			.environmentObject(sc.player.queueInfo)
			.environmentObject(sc.session.helpers.downloadStatus)
			.background(EmptyView().sheet(isPresented: $loginInfo.showModal) {
				LoginView().environmentObject(self.loginInfo)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showAddTracksModal) {
				AddToPlaylistView(session: self.sc.session)
					.environmentObject(self.playlistEditingValues)
					.environmentObject(self.viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showRemoveTracksModal) {
				RemoveFromPlaylistView(session: self.sc.session)
					.environmentObject(self.playlistEditingValues)
					.environmentObject(self.viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showDeleteModal) {
				DeletePlaylist(session: self.sc.session)
					.environmentObject(self.playlistEditingValues)
					.environmentObject(self.viewState)
			})
			.background(EmptyView().sheet(isPresented: $playlistEditingValues.showEditModal) {
				EditPlaylist(session: self.sc.session)
					.environmentObject(self.playlistEditingValues)
					.environmentObject(self.viewState)
			})
	}
}
