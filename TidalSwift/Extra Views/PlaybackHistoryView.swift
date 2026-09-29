//
//  PlaybackHistoryView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 18.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct PlaybackHistoryView: View {
	@Environment(QueueInfo.self) var queueInfo
	
	let session: Session
	let player: Player
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Playback History")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 5)
					VStack {
						Button {
							queueInfo.clearHistory()
						} label: {
							Text("Clear")
						}
						Spacer(minLength: 0)
					}
				}
				if queueInfo.history.isEmpty {
					Text("Empty History")
						.foregroundColor(.secondary)
				} else {
					ForEach(Array(queueInfo.history.enumerated()), id: \.offset) { index, track in
						HStack {
							Text("\(track.title) - \(track.artists.formArtistString())")
								.fontWeight(index == queueInfo.history.count - 1 ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									player.add(tracks: queueInfo.history, .now, playAt: index)
								}
								.accessibilityAction {
									player.add(tracks: queueInfo.history, .now, playAt: index)
								}
								.contextMenu {
									TrackContextMenu(track: track, session: session, player: player)
								}
							Spacer(minLength: 0)
						}
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
