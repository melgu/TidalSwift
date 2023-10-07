//
//  PlaylistGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct PlaylistGridItem: View {
	let playlist: Playlist
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			ZStack(alignment: .bottomTrailing) {
				if let imageUrl = playlist.getImageUrl(session: session, resolution: 320) {
					AsyncImage(url: imageUrl) { image in
						image.resizable().scaledToFit()
					} placeholder: {
						Rectangle()
					}
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
							.foregroundColor(.black)
							.frame(width: 160, height: 160)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
						Text(playlist.title)
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.frame(width: 160)
					}
				}
				if playlist.isOffline(session: session) {
					Image("cloud.fill-big")
						.colorInvert()
						.shadow(radius: SHADOWRADIUS)
						.padding(5)
				}
			}
			Text(playlist.title)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.toolTip(playlist.title)
		.onTapGesture(count: 2) {
			print("Second Click. \(playlist.title)")
			player.add(playlist: playlist, .now)
		}
		.onTapGesture(count: 1) {
			print("First Click. \(playlist.title)")
			viewState.push(playlist: playlist)
		}
		.contextMenu {
			PlaylistContextMenu(playlist: playlist, session: session, player: player)
		}
	}
}
