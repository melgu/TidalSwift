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
	
	var body: some View {
		MasterDetailView(session: session, player: player)
			.environmentObject(player.playbackInfo)
			.environmentObject(viewState)
	}
}

//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
