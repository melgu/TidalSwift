//
//  PlayerInfoView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct PlayerInfoView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		VStack {
			HStack {
				Rectangle()
					.foregroundColor(Color.red)
					.aspectRatio(contentMode: .fit)
				VStack {
					Text("Title")
					Text("Album – Artists")
						.foregroundColor(.gray)
				}
				Spacer()
				VStack {
					HStack {
						Spacer()
						Text("🔀")
							.onTapGesture {
								print("Random")
						}
						Text("⏪")
							.onTapGesture {
								self.player.previous()
						}
						if self.playbackInfo.playing {
							Text("⏸")
								.onTapGesture {
									self.player.pause()
							}
						} else {
							Text("▶️")
								.onTapGesture {
									self.player.play()
							}
						}
						Text("⏩")
							.onTapGesture {
								self.player.next()
						}
						Text("🔁")
							.onTapGesture {
								self.player.clearQueue()
						}
						Spacer()
					}
					ProgressBar()
				}
				.frame(width: 200)
				Spacer()
				Text("----- 🔈")
				Text("***")
			}
			.padding(.top)
			Divider()
		}
		.frame(height: 50)
	}
}

struct ProgressBar : View {
	@EnvironmentObject var playbackInfo: PlaybackInfo
//    @Binding<CGFloat> var value: CGFloat

    var body: some View {
		Rectangle()
			.opacity(0.3)
			.overlay(
				GeometryReader { proxy in
					Rectangle()
						.frame(width: proxy.size.width * self.playbackInfo.fraction)
						.frame(width: proxy.size.width, alignment: .leading)
						.fixedSize(horizontal: true, vertical: false)
						.opacity(1.0)
				}
		)
		.cornerRadius(5)
    }
}

//struct PlayerInfoView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlayerInfoView()
//	}
//}
