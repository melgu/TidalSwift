//
//  VideoGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct VideoGridItem: View {
	let video: Video
	let showArtist: Bool
	let session: Session
	let player: Player
	
	@Environment(Offline.self) private var offline
	
	private var isOffline: Bool {
		offline.isVideoOffline(video: video)
	}
	
	var body: some View {
		VStack {
			if let imageUrl = video.imageUrl(session: session, resolution: 320) {
				AsyncImage(url: imageUrl)
				.aspectRatio(contentMode: .fit)
				.frame(width: 160, height: 160)
				.cornerRadius(CORNERRADIUS)
				.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				.accessibilityHidden(true)
			} else {
				ZStack {
					Rectangle()
						.fill(.black)
						.frame(width: 160, height: 160)
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
					Text(video.title)
						.foregroundStyle(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			HStack {
				Text(video.title)
					.lineLimit(1)
				if video.explicit {
					Text("􀂝")
						.foregroundStyle(.secondary)
						.layoutPriority(1)
				}
				// The thumbnail is wider than high, so a corner badge like the albums' would float below it
				if isOffline {
					Image(systemName: "arrow.down.circle.fill")
						.foregroundStyle(.secondary)
						.accessibilityLabel("Available Offline")
						.layoutPriority(1)
				}
			}
			.frame(width: 160)
			if showArtist {
				Text(video.artists.formArtistString())
					.fontWeight(.light)
					.foregroundStyle(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.help("\(video.title) – \(video.artists.formArtistString())")
		.accessibilityElement(children: .combine)
		#if canImport(AppKit)
		.onTapGesture(count: 2, perform: play)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(.default, play)
		#endif
		.contextMenu {
			VideoContextMenu(video: video, session: session, player: player)
		}
	}
	
	#if canImport(AppKit)
	private func play() {
		Task {
			await player.play(video: video)
		}
	}
	#endif
}
