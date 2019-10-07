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
import Sliders

struct PlayerInfoView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@State var volumeSlider = 1.0
	
	var body: some View {
		VStack {
			GeometryReader { metrics in
				HStack {
					HStack {
						if !self.player.queue.isEmpty {
							HStack {
								URLImageSourceView(
									self.player.queue[self.playbackInfo.currentIndex].getCoverUrl(session: self.session, resolution: 320)!,
									isAnimationEnabled: true,
									label: Text(self.player.queue[self.playbackInfo.currentIndex].album.title)
								)
									.frame(width: 30, height: 30)
									.cornerRadius(CORNERRADIUS)
									.onTapGesture {
										print("Big Cover")
										// TODO: Open new window with cover
										let controller = CoverWindowController(rootView:
											URLImageSourceView(
												self.player.queue[self.playbackInfo.currentIndex].getCoverUrl(session: self.session, resolution: 1280)!,
												isAnimationEnabled: true,
												label: Text(self.player.queue[self.playbackInfo.currentIndex].album.title)
											)
										)
										controller.window?.title = self.player.queue[self.playbackInfo.currentIndex].album.title
										controller.showWindow(nil)
								}
								VStack(alignment: .leading) {
									HStack {
										Text(self.player.queue[self.playbackInfo.currentIndex].title)
										Text(self.player.currentQualityString())
											.fontWeight(.light)
											.foregroundColor(.orange)
										Text(self.player.maxQualityString())
											.fontWeight(.light)
											.foregroundColor(.gray)
										
										
									}
									Text("\(self.player.queue[self.playbackInfo.currentIndex].artists.formArtistString()) – \(self.player.queue[self.playbackInfo.currentIndex].album.title)")
										.foregroundColor(.gray)
								}
								Spacer()
									.layoutPriority(-1)
							}
							.contextMenu {
								TrackContextMenu(track: self.player.queue[self.playbackInfo.currentIndex], session: self.session, player: self.player)
							}
						} else {
							Spacer()
						}
					}
					.frame(width: metrics.size.width / 3)
					
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
						ProgressBar(player: self.player)
					}
					.frame(width: 200)
					Spacer()
						.layoutPriority(-1)
					Slider(value: self.$volumeSlider, in: 0.0...1.0, onEditingChanged: { changed in
						if changed {
							self.player.setVolum(to: Float(self.volumeSlider))
						}
					})
						.frame(width: 80)
					Text("***")
				}
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
			Divider()
		}
	}
}

struct ProgressBar : View {
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	var body: some View {
		HorizontalValueSlider(value: $playbackInfo.fraction, onEditingChanged: {ended  in
			if ended {
				//				print("Changed: \(self.playbackInfo.fraction)")
				self.player.seek(to: Double(self.playbackInfo.fraction))
			}
		})
			.height(5)
			.thickness(5)
			.valueColor(.playbackProgressBarForeground(for: colorScheme))
			.trackColor(.playbackProgressBarBackground(for: colorScheme))
			.thumbSize(CGSize(width: 0, height: 0))
	}
}

//struct PlayerInfoView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlayerInfoView()
//	}
//}
