//
//  QueueView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.09.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct QueueView: View {
	unowned let session: Session
	unowned let player: Player
	
	@EnvironmentObject var queueInfo: QueueInfo
	
	func calculateTotalTime(for tracks: [Track]) -> Int {
		var result = 0
		for track in tracks {
			result += track.duration
		}
		return result
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Queue")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 5)
					VStack {
						Button {
							player.clearQueue(leavingCurrent: true)
						} label: {
							Text("Clear")
						}
						Spacer(minLength: 0)
					}
					VStack(alignment: .trailing) {
						Text("\(queueInfo.queue.count) Tracks")
							.foregroundColor(.secondary)
						Text(secondsToHoursMinutesSecondsString(seconds: calculateTotalTime(for: queueInfo.queue)))
							.foregroundColor(.secondary)
						Spacer()
					}
				}
				if queueInfo.queue.isEmpty {
					Text("Empty Queue")
						.foregroundColor(.secondary)
				} else {
					ForEach(Array(queueInfo.queue.enumerated()), id: \.offset) { index, track in
						HStack {
							Text("\(track.title) - \(track.artists.formArtistString())")
								.fontWeight(index == queueInfo.currentIndex ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									player.play(atIndex: index)
								}
								.contextMenu {
									TrackContextMenu(track: track, session: session, player: player)
								}
							Spacer(minLength: 5)
							Image(systemName: "x.circle.fill")
								.secondaryIconColor()
								.onTapGesture {
									player.removeTrack(atIndex: index)
								}
						}
						.padding(.top, -12)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
