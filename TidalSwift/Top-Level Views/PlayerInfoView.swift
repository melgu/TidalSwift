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
	
	
	@Environment(QueueInfo.self) var queueInfo
	@Environment(TidalSwiftAppModel.self) var appModel
	
	var body: some View {
		VStack {
			GeometryReader { metrics in
				HStack {
					TrackInfoView(player: player, session: session)
						.frame(width: metrics.size.width / 2 - 100)
						.contextMenu {
							if !queueInfo.queue.isEmpty {
								let track = queueInfo.queue[queueInfo.currentIndex]
								TrackContextMenu(track: track, session: session, player: player)
							}
						}
					
					PlaybackControls(player: player)
						.frame(width: 200)
					Spacer()
					VolumeControl(player: player)
					Spacer()
					DownloadIndicator()
					#if canImport(AppKit)
					Button(action: appModel.showLyricsWindow) {
						Image(systemName: "quote.bubble")
							.accessibilityLabel("Lyrics")
							.help("Lyrics")
					}
					.buttonStyle(.plain)
					Button(action: appModel.showQueueWindow) {
						Image(systemName: "list.dash")
							.accessibilityLabel("Queue")
							.help("Queue")
					}
					.buttonStyle(.plain)
					#endif
				}
			}
			.frame(height: 30)
			.padding([.top, .horizontal])
		}
	}
}

struct TrackInfoView: View {
	let player: Player
	let session: Session
	
	@Environment(QueueInfo.self) var queueInfo
	
	var body: some View {
		HStack {
			if !player.queueInfo.queue.isEmpty {
				let track = queueInfo.queue[queueInfo.currentIndex]
				HStack {
					if let coverUrlSmall = track.getCoverUrl(session: session, resolution: 320),
					   let coverUrlBig = track.getCoverUrl(session: session, resolution: 1280) {
						let cover = AsyncImage(url: coverUrlSmall)
							.frame(width: 30, height: 30)
							.cornerRadius(CORNERRADIUS)
						#if canImport(AppKit)
						Button {
							print("Big Cover")
							let title = "\(track.title) – \(track.album.title)"
							let controller = ImageWindowController(
								imageUrl: coverUrlBig,
								title: title
							)
							controller.window?.title = title
							controller.showWindow(nil)
						} label: {
							cover
								.accessibilityLabel("Show cover in new window")
								.help("Show cover in new window")
						}
						.buttonStyle(.plain)
						#else
						cover
							.accessibilityHidden(true)
						#endif
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
	
	@Environment(PlaybackInfo.self) var playbackInfo
	@Environment(QueueInfo.self) var queueInfo
	
	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Spacer()
				Button {
					playbackInfo.shuffle.toggle()
				} label: {
					Image(systemName: "shuffle")
						.foregroundStyle(playbackInfo.shuffle ? Color.accentColor : .primary)
						.accessibilityLabel("Shuffle")
						.accessibilityAddTraits(playbackInfo.shuffle ? .isSelected : [])
						.help("Shuffle")
				}
				.buttonStyle(.plain)
				Group {
					Button {
						player.previous()
					} label: {
						Image(systemName: "backward.fill")
					}
					if playbackInfo.playing {
						Button {
							player.pause()
						} label: {
							Image(systemName: "pause.fill")
						}
					} else {
						Button {
							player.play()
						} label: {
							Image(systemName: "play.fill")
						}
					}
					Button {
						player.next()
					} label: {
						Image(systemName: "forward.fill")
					}
				}
				.buttonStyle(.plain)
				.disabled(queueInfo.queue.isEmpty)
				Button {
					player.playbackInfo.repeatState = player.playbackInfo.repeatState.next()
					print("Repeat: \(player.playbackInfo.repeatState)")
				} label: {
					Image(systemName: playbackInfo.repeatState == .single ? "repeat.1" : "repeat")
						.foregroundStyle(playbackInfo.repeatState == .off ? .primary : Color.accentColor)
						.accessibilityLabel("Repeat")
						.accessibilityValue(repeatStateAccessibilityValue)
						.help("Repeat")
				}
				.buttonStyle(.plain)
				Spacer()
			}
			ProgressBar(player: player)
				.opacity(queueInfo.queue.isEmpty ? 0.5 : 1)
				.disabled(queueInfo.queue.isEmpty)
		}
	}
	
	var repeatStateAccessibilityValue: LocalizedStringResource {
		switch playbackInfo.repeatState {
		case .off: "Off"
		case .all: "All"
		case .single: "One"
		}
	}
}

struct ProgressBar: View {
	let player: Player
	
	@Environment(PlaybackInfo.self) var playbackInfo
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	var body: some View {
		let fraction = Binding(
			get: { playbackInfo.fraction },
			set: { newFraction in
				playbackInfo.fraction = newFraction
				player.seek(to: Double(newFraction))
			}
		)

		GeometryReader { geometry in
			ZStack(alignment: .leading) {
				Rectangle()
					.foregroundStyle(Color.playbackProgressBarBackground(for: colorScheme))
				Rectangle()
					.foregroundStyle(Color.playbackProgressBarForeground(for: colorScheme))
					.frame(width: geometry.size.width * min(max(playbackInfo.fraction, 0), 1))
			}
			.clipShape(.rect(cornerRadius: 3))
			.contentShape(.rect)
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						guard geometry.size.width > 0 else { return }
						fraction.wrappedValue = min(max(value.location.x / geometry.size.width, 0), 1)
					}
			)
		}
		.frame(height: 5)
		.help(playbackInfo.playbackTimeInfo)
		.accessibilityRepresentation {
			Slider(value: fraction, in: 0...1) {
				Text("Playback Position")
			}
			.accessibilityValue(playbackInfo.playbackTimeInfo)
		}
	}
}

struct VolumeControl: View {
	let player: Player
	
	@Environment(PlaybackInfo.self) var playbackInfo
	
	var body: some View {
		@Bindable var playbackInfo = playbackInfo
		
		HStack {
			Button(action: player.toggleMute) {
				speakerSymbol
					.frame(width: 20, alignment: .leading)
					.accessibilityLabel("Mute")
					.accessibilityAddTraits(playbackInfo.volume == 0 ? .isSelected : [])
			}
			.buttonStyle(.plain)
			Slider(value: $playbackInfo.volume, in: 0...1) {
				Text("Volume")
			}
			.labelsHidden()
			.controlSize(.small)
			.tint(.secondary)
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
