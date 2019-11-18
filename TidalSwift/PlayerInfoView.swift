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
								if self.playbackInfo.queue[self.playbackInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 320) != nil {
									URLImageSourceView(
										self.playbackInfo.queue[self.playbackInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 320)!,
										isAnimationEnabled: true,
										label: Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].track.album.title)
									)
										.frame(width: 30, height: 30)
										.cornerRadius(CORNERRADIUS)
										.onTapGesture {
											print("Big Cover")
											let controller = CoverWindowController(rootView:
												URLImageSourceView(
													self.playbackInfo.queue[self.playbackInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 1280)!,
													isAnimationEnabled: true,
													label: Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].track.album.title)
												)
											)
											controller.window?.title = self.playbackInfo.queue[self.playbackInfo.currentIndex].track.album.title
											controller.showWindow(nil)
									}
								} else {
									Rectangle()
										.frame(width: 30, height: 30)
										.cornerRadius(CORNERRADIUS)
								}
								
								VStack(alignment: .leading) {
									HStack {
										Text(self.playbackInfo.queue[self.playbackInfo.currentIndex].track.title)
										Text(self.player.currentQualityString())
											.fontWeight(.light)
											.foregroundColor(.orange)
										Text(self.player.maxQualityString())
											.fontWeight(.light)
											.foregroundColor(.secondary)
										
										
									}
									Text("\(self.playbackInfo.queue[self.playbackInfo.currentIndex].track.artists.formArtistString()) – \(self.playbackInfo.queue[self.playbackInfo.currentIndex].track.album.title)")
										.foregroundColor(.secondary)
								}
								Spacer()
									.layoutPriority(-1)
							}
							.contextMenu {
								TrackContextMenu(track: self.playbackInfo.queue[self.playbackInfo.currentIndex].track, session: self.session, player: self.player)
							}
						} else {
							Spacer()
						}
					}
					.frame(width: metrics.size.width / 2 - 100)
					
					VStack {
						HStack {
							Spacer()
							Text("􀊝")
								.onTapGesture {
									self.playbackInfo.shuffle.toggle()
							}
							.foregroundColor(self.playbackInfo.shuffle ? .accentColor : .primary)
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
							.foregroundColor(self.playbackInfo.repeatState == .off ? .primary : .accentColor)
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
						HSlider(value: self.$playbackInfo.volume, in: 0.0...1.0,
								track:
							HTrack(
								value: self.playbackInfo.volume,
								view: Rectangle()
									.foregroundColor(.secondary)
									.frame(height: 4)
							)
								.background(Color.secondary)
								.frame(height: 4)
								.cornerRadius(3),
								configuration: .init(
									options: .interactiveTrack,
									thumbSize: CGSize(width: 15, height: 15)
							)
							
						)
							.frame(width: 80)
							.layoutPriority(1)
					}
					Spacer()
					Text("􀌮")
						.onTapGesture {
							unowned let appDelegate = NSApp.delegate as? AppDelegate
							appDelegate?.lyrics(self)
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
		HSlider(value: $playbackInfo.fraction,
				track:
			HTrack(
				value: playbackInfo.fraction,
				view: Rectangle()
					.foregroundColor(.playbackProgressBarForeground(for: colorScheme))
					.frame(height: 5),
				mask: Rectangle()
			)
				.background(Color.playbackProgressBarBackground(for: colorScheme))
				.frame(height: 5)
				.cornerRadius(3),
				thumb: EmptyView(),
				configuration: .init(
					options: .interactiveTrack,
					thumbSize: .zero
			),
				onEditingChanged: { ended  in
					if ended {
						self.player.seek(to: Double(self.playbackInfo.fraction))
					}
		}
		)
			.frame(height: 5)
	}
}

//struct PlayerInfoView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlayerInfoView()
//	}
//}
