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
	@ObservedObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		Group {
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
			Slider(value: $playbackInfo.fraction) { ended in
				if ended {
					player.seek(to: Double(playbackInfo.fraction))
				}
			}
		}
	}
}
