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
										.toolTip("Show cover in new window")
										.onTapGesture {
											print("Big Cover")
											let trackTitle = self.queueInfo.queue[self.queueInfo.currentIndex].track.title
											let albumTitle = self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title
											let controller = CoverWindowController(rootView:
												URLImageSourceView(
													self.queueInfo.queue[self.queueInfo.currentIndex].track.getCoverUrl(session: self.session, resolution: 1280)!,
													isAnimationEnabled: true,
													label: Text("\(trackTitle) – \(albumTitle)")
												)
											)
											controller.window?.title = "\(trackTitle) – \(albumTitle)"
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
										Text("\(self.queueInfo.queue[self.queueInfo.currentIndex].track.title)")
										if self.queueInfo.queue[self.queueInfo.currentIndex].track.version != nil {
											Text("(\(self.queueInfo.queue[self.queueInfo.currentIndex].track.version!))")
												.foregroundColor(.secondary)
												.padding(.leading, -5)
												.layoutPriority(-1)
										}
										Text(self.player.currentQualityString())
											.fontWeight(.light)
											.foregroundColor(.orange)
										Text(self.player.maxQualityString())
											.fontWeight(.light)
											.foregroundColor(.secondary)
									}
									.toolTip("\(self.queueInfo.queue[self.queueInfo.currentIndex].track.title)\(self.queueInfo.queue[self.queueInfo.currentIndex].track.version != nil ? " (\(self.queueInfo.queue[self.queueInfo.currentIndex].track.version!))" : "")")
									Text("\(self.queueInfo.queue[self.queueInfo.currentIndex].track.artists.formArtistString()) – \(self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title)")
										.foregroundColor(.secondary)
									.toolTip("\(self.queueInfo.queue[self.queueInfo.currentIndex].track.artists.formArtistString()) – \(self.queueInfo.queue[self.queueInfo.currentIndex].track.album.title)")
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
							Group {
								if self.playbackInfo.shuffle {
									Image(nsImage: NSImage(named: "shuffle")!.tint(color: .controlAccentColor))
								} else {
									Image("shuffle")
										.primaryIconColor()
										.onTapGesture {
											self.playbackInfo.shuffle.toggle()
									}
								}
							}
							.toolTip("Shuffle")
							.onTapGesture {
								self.playbackInfo.shuffle.toggle()
							}
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
							.toolTip("Repeat")
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
						ValueSlider(value: self.$playbackInfo.volume, in: 0.0...1.0)
							.valueSliderStyle(
								HorizontalValueSliderStyle(track: HorizontalValueTrack(view:
									Rectangle()
										.foregroundColor(.secondary)
										.frame(height: 4))
									.background(Color.secondary)
									.frame(height: 4)
									.cornerRadius(3),
														   thumbSize: CGSize(width: 15, height: 15),
														   options: .interactiveTrack)
						)
							.frame(width: 80)
							.layoutPriority(1)
					}
					Spacer()
					DownloadIndicator()
					Image("quote.bubble")
						.primaryIconColor()
						.toolTip("Lyrics")
						.onTapGesture {
							unowned let appDelegate = NSApp.delegate as? AppDelegate
							appDelegate?.lyrics(self)
					}
					Image("list.dash")
						.primaryIconColor()
						.toolTip("Queue")
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
		ValueSlider(value: $playbackInfo.fraction) { ended in
			if ended {
				self.player.seek(to: Double(self.playbackInfo.fraction))
			}
		}
		.valueSliderStyle(
			HorizontalValueSliderStyle(track: HorizontalValueTrack(view:
				Rectangle()
					.foregroundColor(.playbackProgressBarForeground(for: colorScheme))
					.frame(height: 5),
																   mask: Rectangle()
			)
				.background(Color.playbackProgressBarBackground(for: colorScheme))
				.frame(height: 5)
				.cornerRadius(3)
				.toolTip((self.playbackInfo.playbackTimeInfo)),
									   thumb: EmptyView(),
									   thumbSize: .zero,
									   options: .interactiveTrack)
		)
			.frame(height: 5)
	}
}
