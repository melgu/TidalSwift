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
	let viewState: ViewState
	let session: Session
	let player: Player
	
	@EnvironmentObject var loginInfo: LoginInfo
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		MasterDetailView(session: session, player: player)
			.environmentObject(player.playbackInfo)
			.environmentObject(viewState)
			.sheet(isPresented: $loginInfo.showModal) {
				LoginView()
					.environmentObject(self.loginInfo)
		}
		.sheet(isPresented: $playlistEditingValues.showAddTracksModal) {
			AddToPlaylistView(session: self.session)
				.environmentObject(self.playlistEditingValues)
		}
		.sheet(isPresented: $playlistEditingValues.showDeleteModal) {
			DeletePlaylist(session: self.session)
				.environmentObject(self.playlistEditingValues)
		}
		.sheet(isPresented: $playlistEditingValues.showEditModal) {
			EditPlaylist(session: self.session)
				.environmentObject(self.playlistEditingValues)
		}
	}
}

//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
