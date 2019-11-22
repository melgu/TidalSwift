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
	
	@State var lyrics: String?
	
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	@EnvironmentObject var queueInfo: QueueInfo
	
	@State var lastTrack: Track?
	var track: Track? {
		if !queueInfo.queue.isEmpty {
			return queueInfo.queue[queueInfo.currentIndex].track
		} else {
			return nil
		}
	}
	
	var body: some View {
		_ = queueInfo.$currentIndex.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.fetchLyrics() })
		_ = queueInfo.$queue.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.fetchLyrics() })
		
		return ScrollView {
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
					if loadingState == .successful {
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
					} else if loadingState == .loading {
						LoadingSpinner()
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
		.onAppear() {
			self.fetchLyrics()
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func fetchLyrics() {
		if track == lastTrack {
			return
		}
		lastTrack = track
		workItem?.cancel()
		loadingState = .loading
		workItem = createWorkItem()
		if workItem != nil {
			DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
		}
		
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			guard let track = self.track else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
				return
			}
			let t = self.lyricsHandler.getLyrics(for: track)
			DispatchQueue.main.async {
				if t != nil {
					self.lyrics = t
					self.loadingState = .successful
				} else {
					self.loadingState = .error
				}
			}
		}
	}
}
