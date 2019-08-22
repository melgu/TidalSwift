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
	let session: Session
	let player: Player
	let playbackInfo: PlaybackInfo
	
	var body: some View {
		MasterDetailView(session: session, player: player)
			.environmentObject(playbackInfo)
	}
}

//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
