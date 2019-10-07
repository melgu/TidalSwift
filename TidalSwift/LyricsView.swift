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
	let track: Track
	let lyrics: String
	
	init(track: Track) {
		self.track = track
		self.lyrics = Lyrics.getLyrics(for: track)
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text(track.title)
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				Text(track.artists.formArtistString())
					.font(.headline)
					.padding(.bottom)
				if lyrics != "" {
					Text(lyrics)
						.contextMenu {
							if lyrics != "" {
								Button(action: {
									print("Copy")
									let pb = NSPasteboard.init(name: NSPasteboard.Name.general)
									pb.declareTypes([.string], owner: nil)
									pb.setString(self.lyrics, forType: .string)
								}) {
									Text("Copy")
								}
							}
					}
				} else {
					Text("No Lyrics available")
						.foregroundColor(.gray)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

//struct LyricsView_Previews: PreviewProvider {
//	static var previews: some View {
//		LyricsView()
//	}
//}
