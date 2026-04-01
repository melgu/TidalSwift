//
//  PlayerInfoView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Sliders

struct PlayerInfoView: View {
	let session: Session
	let player: Player
	
	
	@EnvironmentObject var queueInfo: QueueInfo
	@EnvironmentObject var appModel: TidalSwiftAppModel
	
	var body: some View {
		VStack {
            
			GeometryReader { metrics in
				HStack {
					TrackInfoView(player: player, session: session)
						.frame(width: metrics.size.width / 2 - 107)
						.contextMenu {
							if !queueInfo.queue.isEmpty {
								let track = queueInfo.queue[0].track
								TrackContextMenu(track: track, session: session, player: player)
							}
						}
                    VStack{
                        PlaybackControls(player: player)
                            .frame(width: 200)
                        ProgressBar(player: player).padding([.horizontal]).frame(width: 400)
                    }
					
					Spacer()
					VolumeControl(player: player)
					
					
					#if canImport(AppKit)
					Image(systemName: "quote.bubble")
						.help("Lyrics")
						.onTapGesture {
							appModel.showLyricsWindow()
						}
					Image(systemName: "list.dash")
						.help("Queue")
						.onTapGesture {
							appModel.showQueueWindow()
						}
					#endif
				}
                
            }
			
            .padding( [.vertical,.horizontal])
            .frame(alignment: .center)
            
            
        }
	}
}

struct TrackInfoView: View {
	let player: Player
	let session: Session
	
	@EnvironmentObject var queueInfo: QueueInfo
    @EnvironmentObject var playbackInfo: PlaybackInfo
	var body: some View {
		HStack {
            if player.getCurrentlyPlayingTrack() != nil{
               
                let track = player.getCurrentlyPlayingTrack()!
				HStack {
					if let coverUrlSmall = track.getCoverUrl(session: session, resolution: 320),
					   let coverUrlBig = track.getCoverUrl(session: session, resolution: 1280) {
						AsyncImage(url: coverUrlSmall) { image in
							image.resizable().scaledToFit()
						} placeholder: {
							Rectangle()
						}
						.frame(width: 30, height: 30)
						.cornerRadius(CORNERRADIUS)
						.help("Show cover in new window")
						#if canImport(AppKit)
						.onTapGesture {
							print("Big Cover")
							let title = "\(track.title) – \(track.album.title)"
							let controller = ImageWindowController(
								imageUrl: coverUrlBig,
								title: title
							)
							controller.window?.title = title
							controller.showWindow(nil)
						}
						#endif
						.accessibilityHidden(true)
					} else {
						Rectangle()
							.foregroundColor(.black)
							.frame(width: 30, height: 30)
							.cornerRadius(CORNERRADIUS)
					}
					
					VStack(alignment: .leading) {
						HStack {
							Text("\(track.title)")
							if let version = track.version {
								Text(version)
									.foregroundColor(.secondary)
									.padding(.leading, -5)
									.layoutPriority(-1)
							}
							Text(player.currentQualityString())
								.fontWeight(.light)
								.foregroundColor(.orange)
								.help("Current Quality")
							Text(player.maxQualityString())
								.fontWeight(.light)
								.foregroundColor(.secondary)
								.help("Maximum available quality")
						}
						.help(trackToolTipString(for: track))
						Text("\(track.artists.formArtistString()) – \(track.album.title)")
							.foregroundColor(.secondary)
							.help("\(track.artists.formArtistString()) – \(track.album.title)")
					}
					Spacer()
						.layoutPriority(-1)
				}
			} else {
				Spacer()
			}
		}
	}
	
	func trackToolTipString(for track: Track) -> String {
		var s = track.title
		if let version = track.version {
			s += " (\(version))"
		}
		s += " – \(track.artists.formArtistString())"
		return s
	}
}

struct PlaybackControls: View {
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Spacer()
				Group {
					if playbackInfo.shuffle {
                        Image(systemName: "shuffle.circle.fill")
                            .resizable()
                            .frame(width:15, height:15)
							#if canImport(AppKit)
							.tint(.controlAccentColor)
							#else
							.tint(.secondary)
							#endif
					} else {
						Image(systemName: "shuffle.circle")
                            .resizable()
                            .frame(width:15, height:15)
                        
					}
				}
				.help("Shuffle")
				.onTapGesture {
					playbackInfo.shuffle.toggle()
					if playbackInfo.shuffle {
						player.queueInfo.setPlaybackMode(.shuffled)
					} else {
						// If repeat single is active, keep repeatOne; else normal/repeatAll
						switch player.playbackInfo.repeatState {
						case .single:
							player.queueInfo.setPlaybackMode(.repeatOne)
						case .all:
							player.queueInfo.setPlaybackMode(.repeatAll)
						case .off:
							player.queueInfo.setPlaybackMode(.normal)
						}
					}
				}
				Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width:15, height:12)
                
					.onTapGesture {
						player.previous()
					}
				if playbackInfo.playing {
					Image(systemName: "pause.fill")
                        .resizable()
                        .frame(width:15, height:15)
						.onTapGesture {
							player.pause()
						}
				} else {
					Image(systemName: "play.fill")
                        .resizable()
                        .frame(width:15,height: 15)
						.onTapGesture {
							player.play()
						}
				}
				Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width:15, height:12)
					.onTapGesture {
						player.next()
					}
				Group {
					if playbackInfo.repeatState == .single {
						Image(systemName: "repeat.1.circle.fill")
                            .resizable()
                            .frame(width:15, height:15)
                        
							#if canImport(AppKit)
							.tint(.controlAccentColor)
							#else
							.tint(.secondary)
							#endif
					} else if playbackInfo.repeatState == .all {
						Image(systemName: "repeat.circle.fill")
                            .resizable()
                            .frame(width:15, height:15)
							#if canImport(AppKit)
							.tint(.controlAccentColor)
							#else
							.tint(.secondary)
							#endif
					} else {
						Image(systemName: "repeat.circle")
                            .resizable()
                            .frame(width:15, height:15)
					}
				}
				.help("Repeat")
				.onTapGesture {
					player.playbackInfo.repeatState = player.playbackInfo.repeatState.next()
					switch player.playbackInfo.repeatState {
					case .off:
						if playbackInfo.shuffle {
							player.queueInfo.setPlaybackMode(.shuffled)
						} else {
							player.queueInfo.setPlaybackMode(.normal)
						}
					case .all:
						if playbackInfo.shuffle {
							player.queueInfo.setPlaybackMode(.shuffled)
						} else {
							player.queueInfo.setPlaybackMode(.repeatAll)
						}
					case .single:
						player.queueInfo.setPlaybackMode(.repeatOne)
					}
				}
				Spacer()
			}
			
		}
	}
}

struct ProgressBar: View {
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	var body: some View {
		ValueSlider(value: $playbackInfo.fraction) { down in
			if down { // Only apply while scrubbing, not when releasing
				player.seek(to: Double(playbackInfo.fraction))
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
			.help((playbackInfo.playbackTimeInfo)),
			thumb: EmptyView(),
			thumbSize: .zero,
			options: .interactiveTrack)
		)
		.frame(height: 5)
	}
}

struct VolumeControl: View {
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		HStack {
			speakerSymbol
				.frame(width: 20, alignment: .leading)
				.onTapGesture {
					player.toggleMute()
				}
			ValueSlider(value: $playbackInfo.volume, in: 0.0...1.0)
				.valueSliderStyle(
					HorizontalValueSliderStyle(track:
												HorizontalValueTrack(view:
													Rectangle()
														.foregroundColor(.secondary)
														.frame(height: 4)
												)
												.background(Color.secondary)
												.frame(height: 4)
												.cornerRadius(3),
											   thumbSize: CGSize(width: 15, height: 15),
											   options: .interactiveTrack)
				)
				.frame(width: 80, height: 30)
				.layoutPriority(1)
		}
	}
	
	@ViewBuilder
	var speakerSymbol: some View {
		if playbackInfo.volume > 0.66 {
			Image(systemName: "speaker.3.fill")
		} else if playbackInfo.volume > 0.33 {
			Image(systemName: "speaker.2.fill")
		} else if playbackInfo.volume > 0 {
			Image(systemName: "speaker.1.fill")
		} else {
			Image(systemName: "speaker.fill") // or 􀊣
		}
	}
}

