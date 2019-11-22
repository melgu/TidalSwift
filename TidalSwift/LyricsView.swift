//
//  LyricsView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct LyricsView: View {
	let lyricsHandler = Lyrics()
	
	@EnvironmentObject var queueInfo: QueueInfo
	
	var track: Track? {
		if !queueInfo.queue.isEmpty {
			return queueInfo.queue[queueInfo.currentIndex].track
		} else {
			return nil
		}
	}
	var lyrics: String? {
		if let track = track {
			return lyricsHandler.getLyrics(for: track)
		} else {
			return nil
		}
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if track != nil {
					HStack {
						Text(track!.title)
							.font(.title)
							.padding(.bottom)
						Spacer(minLength: 0)
					}
					Text(track!.artists.formArtistString())
						.font(.headline)
						.padding(.bottom)
					if lyrics != nil {
						Text(lyrics!)
							.contextMenu {
								Button(action: {
									print("Copy")
									let pb = NSPasteboard.init(name: NSPasteboard.Name.general)
									pb.declareTypes([.string], owner: nil)
									pb.setString(self.lyrics!, forType: .string)
								}) {
									Text("Copy")
								}
						}
					} else {
						Text("No Lyrics available")
							.foregroundColor(.secondary)
					}
				} else {
					HStack {
						Text("No track")
							.font(.title)
							.padding(.bottom)
						Spacer(minLength: 0)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
		
	}
}
