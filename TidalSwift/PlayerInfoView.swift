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
import SwiftUIExtensions

struct PlayerInfoView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@EnvironmentObject var queueInfo: QueueInfo
	
	var body: some View {
		VStack {
			GeometryReader { metrics in
				HStack {
					HStack {
						if !self.player.queueInfo.queue.isEmpty {
							HStack {
								if self.queueInfo.queue[self.queueInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 320) != nil {
									URLImageSourceView(
										self.queueInfo.queue[self.queueInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 320)!,
										isAnimationEnabled: true,
										label: Text(self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title)
									)
										.frame(width: 30, height: 30)
										.cornerRadius(CORNERRADIUS)
										.onTapGesture {
											print("Big Cover")
											let controller = CoverWindowController(rootView:
												URLImageSourceView(
													self.queueInfo.queue[self.queueInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 1280)!,
													isAnimationEnabled: true,
													label: Text(self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title)
												)
											)
											controller.window?.title = self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title
											controller.showWindow(nil)
									}
								} else {
									Rectangle()
										.foregroundColor(.black)
										.frame(width: 30, height: 30)
										.cornerRadius(CORNERRADIUS)
								}
								
								VStack(alignment: .leading) {
									HStack {
										Text(self.queueInfo.queue[self.queueInfo.currentIndex].track.title)
										Text(self.player.currentQualityString())
											.fontWeight(.light)
											.foregroundColor(.orange)
										Text(self.player.maxQualityString())
											.fontWeight(.light)
											.foregroundColor(.secondary)
										
										
									}
									Text("\(self.queueInfo.queue[self.queueInfo.currentIndex].track.artists.formArtistString()) – \(self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title)")
										.foregroundColor(.secondary)
								}
								Spacer()
									.layoutPriority(-1)
							}
						} else {
							Spacer()
						}
					}
					.frame(width: metrics.size.width / 2 - 100)
					.contextMenu {
						if !self.queueInfo.queue.isEmpty {
							TrackContextMenu(track: self.queueInfo.queue[self.queueInfo.currentIndex].track, session: self.session, player: self.player)
						}
					}
					
					VStack {
						HStack {
							Spacer()
							Image("shuffle")
								.primaryIconColor()
								.onTapGesture {
									self.playbackInfo.shuffle.toggle()
							}
							.foregroundColor(self.playbackInfo.shuffle ? .accentColor : .primary)
							Image("backward.fill")
								.primaryIconColor()
								.onTapGesture {
									self.player.previous()
							}
							if self.playbackInfo.playing {
								Image("pause.fill")
									.primaryIconColor()
									.onTapGesture {
										self.player.pause()
								}
							} else {
								Image("play.fill")
									.primaryIconColor()
									.onTapGesture {
										self.player.play()
								}
							}
							Image("forward.fill")
								.primaryIconColor()
								.onTapGesture {
									self.player.next()
							}
							Group {
								if self.playbackInfo.repeatState == .single {
									Image(nsImage: NSImage(named: "repeat1")!.tint(color: .controlAccentColor))
								} else if self.playbackInfo.repeatState == .all {
									Image(nsImage: NSImage(named: "repeat")!.tint(color: .controlAccentColor))
								} else {
									Image("repeat")
									.primaryIconColor()
								}
							}
							.onTapGesture {
								self.player.playbackInfo.repeatState = self.player.playbackInfo.repeatState.next()
								print("Repeat: \(self.player.playbackInfo.repeatState)")
							}
							Spacer()
						}
						ProgressBar(player: self.player)
					}
					.frame(width: 200)
					Spacer()
					HStack {
						self.speakerSymbol()
							.frame(width: 20, alignment: .leading)
							.onTapGesture {
								self.player.toggleMute()
						}
						HSlider(value: self.$playbackInfo.volume, in: 0.0...1.0,
								track:
							HTrack(
								value: self.playbackInfo.volume,
								view: Rectangle()
									.foregroundColor(.black)
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
					DownloadIndicator()
					Image("quote.bubble")
						.primaryIconColor()
						.onTapGesture {
							unowned let appDelegate = NSApp.delegate as? AppDelegate
							appDelegate?.lyrics(self)
					}
					Image("list.dash")
						.primaryIconColor()
						.onTapGesture {
							unowned let appDelegate = NSApp.delegate as? AppDelegate
							appDelegate?.queue(self)
					}
				}
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
			Divider()
		}
	}
	
	func speakerSymbol() -> some View {
		Group {
			Group { () -> Image in
				if playbackInfo.volume > 0.66 {
					return Image("speaker.3.fill")
				} else if playbackInfo.volume > 0.33 {
					return Image("speaker.2.fill")
				} else if playbackInfo.volume > 0 {
					return Image("speaker.1.fill")
				} else {
					return Image("speaker.fill") // or 􀊣
				}
			}
			.primaryIconColor()
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
