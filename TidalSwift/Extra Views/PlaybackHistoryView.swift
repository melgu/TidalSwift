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
	@EnvironmentObject var queueInfo: QueueInfo
	
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
					ForEach(queueInfo.history) { item in
						HStack {
							Text("\(item.track.title) - \(item.track.artists.formArtistString())")
								.fontWeight(item.id == queueInfo.history.count - 1 ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									player.add(tracks: queueInfo.history.map { $0.track }, .now, playAt: item.id)
								}
								.contextMenu {
									TrackContextMenu(track: item.track, session: session, player: player)
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
