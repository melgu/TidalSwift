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
	
	var body: some View {
		VStack {
			GeometryReader { metrics in
				HStack {
					HStack {
						if !self.player.playbackInfo.queue.isEmpty {
							HStack {
								URLImageSourceView(
									self.playbackInfo.queue[self.playbackInfo.currentIndex].getCoverUrl(session: self.session, resolution: 320)!,
									isAnimationEnabled: true,
									label: Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].album.title)
								)
									.frame(width: 30, height: 30)
									.cornerRadius(CORNERRADIUS)
									.onTapGesture {
										print("Big Cover")
										let controller = CoverWindowController(rootView:
											URLImageSourceView(
												self.playbackInfo.queue[self.playbackInfo.currentIndex].getCoverUrl(session: self.session, resolution: 1280)!,
												isAnimationEnabled: true,
												label: Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].album.title)
											)
										)
										controller.window?.title = self.playbackInfo.queue[self.playbackInfo.currentIndex].album.title
										controller.showWindow(nil)
								}
								VStack(alignment: .leading) {
									HStack {
										Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].title)
										Text(self.player.currentQualityString())
											.fontWeight(.light)
											.foregroundColor(.orange)
										Text(self.player.maxQualityString())
											.fontWeight(.light)
											.foregroundColor(.gray)
										
										
									}
									Text("\(self.playbackInfo.queue[self.playbackInfo.currentIndex].artists.formArtistString()) – \(self.playbackInfo.queue[self.playbackInfo.currentIndex].album.title)")
										.foregroundColor(.gray)
								}
								Spacer()
									.layoutPriority(-1)
							}
							.contextMenu {
								TrackContextMenu(track: self.playbackInfo.queue[self.playbackInfo.currentIndex], session: self.session, player: self.player)
							}
						} else {
							Spacer()
						}
					}
					.frame(width: metrics.size.width / 3)
					
					VStack {
						HStack {
							Spacer()
							Text("􀊝")
								.onTapGesture {
									self.playbackInfo.shuffle.toggle()
							}
							.foregroundColor(self.playbackInfo.shuffle ? .blue : .black)
							Text("􀊊")
								.onTapGesture {
									self.player.previous()
							}
							if self.playbackInfo.playing {
								Text("􀊆")
									.onTapGesture {
										self.player.pause()
								}
							} else {
								Text("􀊄")
									.onTapGesture {
										self.player.play()
								}
							}
							Text("􀊌")
								.onTapGesture {
									self.player.next()
							}
							Text(self.playbackInfo.repeatState == .single ? "􀊟" : "􀊞")
								.onTapGesture {
									print("Repeat")
									self.player.playbackInfo.repeatState = self.player.playbackInfo.repeatState.next()
							}
							.foregroundColor(self.playbackInfo.repeatState == .off ? .black : .blue)
							Spacer()
						}
						ProgressBar(player: self.player)
					}
					.frame(width: 200)
					Spacer()
					HStack {
						Text(self.speakerSymbol())
							.frame(width: 20, alignment: .leading)
							.onTapGesture {
								self.player.toggleMute()
						}
						HorizontalValueSlider(value: self.$playbackInfo.volume, in: 0.0...1.0)
							.trackColor(.gray)
							.valueColor(.gray)
							.thumbSize(CGSize(width: 15, height: 15))
							.thumbBorderWidth(0.5)
							.thumbBorderColor(Color(hue: 0, saturation: 0, brightness: 0.7))
							.thumbShadowRadius(0)
							.thumbShadowColor(Color(.displayP3, white: 0, opacity: 0.2))
							.frame(width: 80)
							.layoutPriority(1)
					}
					Spacer()
					Text("􀌮")
						.onTapGesture {
							if !self.playbackInfo.queue.isEmpty {
								Lyrics.showLyricsWindow(for: self.playbackInfo.queue[self.playbackInfo.currentIndex])
							}
					}
					Text("􀋱")
						.onTapGesture {
							self.player.showQueueWindow()
					}
				}
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
			Divider()
		}
	}
	
	func speakerSymbol() -> String {
		if playbackInfo.volume > 0.66 {
			return "􀊩"
		} else if playbackInfo.volume > 0.33 {
			return "􀊧"
		} else if playbackInfo.volume > 0 {
			return "􀊥"
		} else {
			return "􀊡" // or 􀊣
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
