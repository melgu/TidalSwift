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
						Text(secondsToHoursMinutesSecondsString(seconds: calculateTotalTime(for: queueInfo.queue.map { $0.track })))
							.foregroundColor(.secondary)
						Spacer()
					}
				}
				if queueInfo.queue.isEmpty {
					Text("Empty Queue")
						.foregroundColor(.secondary)
				} else {
					ForEach(queueInfo.queue) { item in
						HStack {
							Text("\(item.track.title) - \(item.track.artists.formArtistString())")
								.fontWeight(item.id == queueInfo.currentIndex ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									player.play(atIndex: item.id)
								}
								.contextMenu {
									TrackContextMenu(track: item.track, session: session, player: player)
								}
							Spacer(minLength: 5)
							Image("x.circle.fill")
								.secondaryIconColor()
								.onTapGesture {
									player.removeTrack(atIndex: item.id)
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
