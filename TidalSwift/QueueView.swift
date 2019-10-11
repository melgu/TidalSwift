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
	let session: Session
	unowned let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Queue")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				if playbackInfo.queue.isEmpty {
					Text("Empty Queue")
						.foregroundColor(.gray)
				} else {
					ForEach(0..<playbackInfo.queue.count) { i in
						Text("\(self.playbackInfo.queue[i].title) - \(self.playbackInfo.queue[i].artists.formArtistString())")
							.fontWeight(i == self.playbackInfo.currentIndex ? .bold : .regular)
							.lineLimit(1)
							.onTapGesture(count: 2) {
								self.player.play(atIndex: i)
						}
						.contextMenu {
							TrackContextMenu(track: self.playbackInfo.queue[i], session: self.session, player: self.player)
						}
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

//struct QueueView_Previews: PreviewProvider {
//	static var previews: some View {
//		QueueView()
//	}
//}
