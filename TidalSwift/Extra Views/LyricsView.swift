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
	let session: Session
	
	@Environment(QueueInfo.self) private var queueInfo
	
	@State private var loadingState: LoadingState = .loading
	
	@State private var lyrics: String?
	
	private var track: Track? {
		queueInfo.currentItem
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if let track = track {
					HStack {
						Text(track.title)
							.font(.title)
							.padding(.bottom)
						Spacer(minLength: 0)
					}
					Text(track.artists.formArtistString())
						.font(.headline)
						.padding(.bottom)
					if loadingState == .successful, let lyrics = lyrics {
						Text(lyrics)
							.contextMenu {
								Button {
									print("Copy Lyrics")
									Pasteboard.copy(string: lyrics)
								} label: {
									Text("Copy")
								}
							}
					} else if loadingState == .loading {
						FullscreenLoadingSpinner(.loading)
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
		.task(id: queueInfo.queue) {
			await fetchLyrics()
		}
		.task(id: queueInfo.currentIndex) {
			await fetchLyrics()
		}
	}
	
	private func fetchLyrics() async {
		guard let track else {
			lyrics = nil
			loadingState = .error
			return
		}
		loadingState = .loading
		lyrics = await track.getLyrics(session: session)?.lyrics
		loadingState = lyrics == nil ? .error : .successful
	}
}
