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
					ForEach(Array(queueInfo.history.enumerated()), id: \.offset) { index, item in
						PlaybackHistoryRow(
							track: item.track,
							isLatest: index == queueInfo.history.count - 1,
							session: session,
							player: player
						)
						.onTapGesture(count: 2) {
							// Rebuild the play queue with the full history and play at the tapped index
							let tracks = queueInfo.history.map { $0.track }
							player.add(tracks: tracks, .now)
						}
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
struct PlaybackHistoryRow: View {
    let track: Track
    let isLatest: Bool
    let session: Session
    let player: Player

    var body: some View {
        let title = track.title
        let artistString = track.artists.formArtistString()
        let display = "\(title) - \(artistString)"

        return HStack {
            Text(display)
                .fontWeight(isLatest ? .bold : .regular)
                .lineLimit(1)
                .onTapGesture(count: 2) {
                    player.add(tracks: [track], .now)
                }
                .contextMenu {
                    TrackContextMenu(track: track, session: session, player: player)
                }
            Spacer(minLength: 0)
        }
    }
}

