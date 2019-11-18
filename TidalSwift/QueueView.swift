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
	
	@EnvironmentObject var sc: SessionContainer
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
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
						Button(action: {
							self.sc.player.clearQueue()
						}) {
							Text("Clear")
						}
						Spacer(minLength: 0)
					}
					VStack(alignment: .leading) {
						Text("\(playbackInfo.queue.count) Tracks")
							.foregroundColor(.secondary)
						Text(secondsToHoursMinutesSecondsString(seconds: calculateTotalTime(for: playbackInfo.queue.map { $0.track } )))
							.foregroundColor(.secondary)
						Spacer()
					}
				}
				if playbackInfo.queue.isEmpty {
					Text("Empty Queue")
						.foregroundColor(.secondary)
				} else {
					ForEach(playbackInfo.queue) { item in
						HStack {
							Text("\(item.track.title) - \(item.track.artists.formArtistString())")
								.fontWeight(item.id == self.playbackInfo.currentIndex ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									self.player.play(atIndex: item.id)
							}
							.contextMenu {
								TrackContextMenu(track: item.track, session: self.session, player: self.player)
							}
							Spacer(minLength: 5)
							Text("􀁏")
								.foregroundColor(.secondary)
								.onTapGesture {
									self.player.removeTrack(atIndex: item.id)
							}
						}
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct QueueItem: Codable, Identifiable {
	let id: Int
	let track: Track
}

//struct QueueView_Previews: PreviewProvider {
//	static var previews: some View {
//		QueueView()
//	}
//}
