//
//  PlayerInfoView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct PlayerInfoView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		VStack {
			HStack {
				if !player.queue.isEmpty {
					Rectangle()
//					URLImageSourceView(
//						player.queue[0].getCoverUrl(session: session, resolution: 320)!,
//						isAnimationEnabled: true,
//						label: Text(player.queue[self.player.currentIndex].album.title)
//					)
						.frame(width: 30, height: 30)
						.onTapGesture {
							print("Big Cover")
							// TODO: Open new window with cover
							let controller = CoverWindowController(rootView:
								Rectangle()
//								URLImageSourceView(
//									self.player.queue[0].getCoverUrl(session: self.session, resolution: 1280)!,
//									isAnimationEnabled: true,
//									label: Text(self.player.queue[self.player.currentIndex].album.title)
//								)
							)
							controller.window?.title = self.player.queue[self.player.currentIndex].album.title
							controller.showWindow(nil)
					}
					VStack(alignment: .leading) {
						Text(player.queue[self.player.currentIndex].title)
						Text("\(player.queue[self.player.currentIndex].artists.formArtistString()) – \(player.queue[self.player.currentIndex].album.title)")
							.foregroundColor(.gray)
					}
				}
				Spacer()
					.layoutPriority(-1)
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
					.layoutPriority(-1)
				Text("----- 🔈")
				Text("***")
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
			Divider()
		}
		
	}
}

struct ProgressBar : View {
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
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
			.frame(height: 5)
	}
}

//struct PlayerInfoView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlayerInfoView()
//	}
//}
