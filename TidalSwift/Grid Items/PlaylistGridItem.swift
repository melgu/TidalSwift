//
//  PlaylistGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "PlaylistGridItem")

struct PlaylistGridItem: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	@Environment(Offline.self) private var offline
	
	private var isOffline: Bool {
		offline.isPlaylistOffline(playlist: playlist)
	}
	
	var body: some View {
		VStack {
			ZStack(alignment: .bottomTrailing) {
				if let imageUrl = playlist.imageUrl(session: session, resolution: 320) {
					AsyncImage(url: imageUrl)
					.aspectRatio(contentMode: .fill)
					.frame(width: 160, height: 160)
					.contentShape(Rectangle())
					.clipped()
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
						Text(playlist.title)
							.foregroundStyle(.white)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.frame(width: 160)
					}
				}
				if isOffline {
					Image(systemName: "cloud.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 30)
						.foregroundStyle(.white)
						.shadow(radius: SHADOWRADIUS)
						.padding(5)
				}
			}
			Text(playlist.title)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.help(playlist.title)
		.onTapGesture(count: 2, perform: play)
		.onTapGesture(count: 1, perform: open)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(.default, open)
		.accessibilityAction(named: "Play", play)
		.contextMenu {
			PlaylistContextMenu(playlist: playlist, session: session, player: player)
		}
	}
	
	private func open() {
		logger.debug("First Click. \(playlist.title)")
		viewState.push(playlist: playlist)
	}
	
	private func play() {
		logger.debug("Second Click. \(playlist.title)")
		player.add(playlist: playlist, .now)
	}
}
