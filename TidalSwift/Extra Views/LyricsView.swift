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
	@EnvironmentObject var queueInfo: QueueInfo
	
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	@State var lyrics: String?
	
	var track: Track? {
		queueInfo.currentItem?.track
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
			loadingState = .error
			return
		}
		do {
			lyrics = try await Lyrics.shared.lyrics(for: track)
		} catch {
			loadingState = .error
		}
	}
}
