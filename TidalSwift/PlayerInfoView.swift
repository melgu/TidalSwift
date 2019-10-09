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
	@State var previousValue = 1.0
	@State var muted = false
	
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
							Text("􀊝")
								.onTapGesture {
									print("Shuffle")
							}
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
							Text("􀊞") // 􀊟
								.onTapGesture {
									print("Repeat")
									self.player.clearQueue()
							}
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
								print("Mute")
								if self.muted {
									self.volumeSlider = self.previousValue
								} else {
									self.previousValue = self.volumeSlider
									self.volumeSlider = 0
								}
								self.player.setVolume(to: Float(self.volumeSlider))
								self.muted.toggle()
						}
						HorizontalValueSlider(value: self.$volumeSlider, in: 0.0...1.0, onEditingChanged: { changed  in
							if changed {
								self.muted = false
								self.player.setVolume(to: Float(self.volumeSlider))
							}
						})
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
							if !self.player.queue.isEmpty {
								let controller = ResizableWindowController(rootView:
									LyricsView(track: self.player.queue[self.playbackInfo.currentIndex])
								)
								let track = self.player.queue[self.playbackInfo.currentIndex]
								controller.window?.title = "\(track.title) – \(track.artists.formArtistString())"
								controller.showWindow(nil)
							}
					}
					Text("􀋱")
						.onTapGesture {
							let controller = ResizableWindowController(rootView:
								Text("Queue")
							)
							controller.window?.title = "Queue"
							controller.showWindow(nil)
					}
				}
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
			Divider()
		}
	}
	
	func speakerSymbol() -> String {
		if volumeSlider > 0.66 {
			return "􀊩"
		} else if volumeSlider > 0.33 {
			return "􀊧"
		} else if volumeSlider > 0 {
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
