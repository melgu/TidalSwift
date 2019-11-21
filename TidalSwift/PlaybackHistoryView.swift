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
	@EnvironmentObject var sc: SessionContainer
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Playback History")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 5)
					VStack {
						Button(action: {
							self.playbackInfo.clearHistory()
						}) {
							Text("Clear")
						}
						Spacer(minLength: 0)
					}
				}
				if playbackInfo.history.isEmpty {
					Text("Empty History")
						.foregroundColor(.secondary)
				} else {
					ForEach(playbackInfo.history) { item in
						HStack {
							Text("\(item.track.title) - \(item.track.artists.formArtistString())")
								.fontWeight(item.id == self.playbackInfo.history.count-1 ? .bold : .regular)
								.lineLimit(1)
								.onTapGesture(count: 2) {
									self.sc.player.clearQueue()
									self.sc.player.add(tracks: self.playbackInfo.history.map { $0.track }, .last)
									self.sc.player.play(atIndex: item.id)
							}
							.contextMenu {
								TrackContextMenu(track: item.track, session: self.sc.session, player: self.sc.player)
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
