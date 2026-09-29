//
//  TouchBarView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct TouchBarView: View {
	let player: Player
	@Bindable var playbackInfo: PlaybackInfo
	
	var body: some View {
		Button(action: {
			player.previous()
		}) {
			Text("Backward")
		}
		if playbackInfo.playing {
			Button(action: {
				player.pause()
			}) {
				Text("Pause")
			}
		} else {
			Button(action: {
				player.play()
			}) {
				Text("Play")
			}
		}
		Button(action: {
			player.next()
		}) {
			Text("Forward")
		}
		Slider(value: $playbackInfo.fraction) { down in
			if !down { // Only apply on finger lift
				player.seek(to: Double(playbackInfo.fraction))
			}
		}
	}
}
