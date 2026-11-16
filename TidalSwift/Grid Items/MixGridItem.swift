//
//  MixGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "MixGridItem")

struct MixGridItem: View {
	let mix: MixesItem
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	
	var body: some View {
		VStack {
			MixImage(mix: mix, highResolutionImages: false)
				.frame(width: 160, height: 160)
				.cornerRadius(CORNERRADIUS)
				.shadow(radius: SHADOWRADIUS, y: SHADOWY)
				.accessibilityHidden(true)
			
			Text(mix.title)
				.frame(width: 160)
			Text(mix.subTitle)
				.fontWeight(.light)
				.foregroundStyle(Color.secondary)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.onTapGesture(count: 2, perform: play)
		.onTapGesture(count: 1, perform: open)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(.default, open)
		.accessibilityAction(named: "Play", play)
		.contextMenu {
			MixContextMenu(mix: mix, session: session, player: player)
		}
	}
	
	private func open() {
		logger.debug("First Click. \(mix.title)")
		viewState.push(mix: mix)
	}
	
	private func play() {
		logger.debug("Second Click. \(mix.title)")
		Task {
			if let tracks = await session.mixPlaylistTracks(mixId: mix.id) {
				player.add(tracks: tracks, .now)
			}
		}
	}
}

struct MixImage: View {
	let mix: MixesItem
	let highResolutionImages: Bool
	
	private let lowResolution: Int = 160
	private let highResolution: Int = 480
	
	var body: some View {
		if let imageUrl = mix.imageUrl(resolution: highResolutionImages ? highResolution : lowResolution) {
			AsyncImage(url: imageUrl)
		} else {
			Rectangle()
		}
	}
}
