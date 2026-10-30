//
//  LyricsView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "LyricsView")

struct LyricsView: View {
	let session: Session
	let player: Player
	
	@Environment(QueueInfo.self) private var queueInfo
	@Environment(PlaybackInfo.self) private var playbackInfo
	
	@State private var loadingState: LoadingState = .loading
	
	@State private var lyrics: String?
	@State private var syncedLines: [SyncedLyricsLine]?
	@State private var fullyVisibleLines = Set<Int>()
	
	private var track: Track? {
		queueInfo.currentItem
	}
	
	var body: some View {
		let activeLine = playbackInfo.activeLyricsLine
		ScrollViewReader { proxy in
			ScrollView {
				VStack(alignment: .leading) {
					if let track = track {
						HStack {
							Text(track.title)
								.font(.title)
								.padding(.bottom)
							Spacer(minLength: 0)
							if loadingState == .successful, syncedLines != nil {
								Text("LIVE")
									.font(.caption.bold())
									.foregroundStyle(.white)
									.padding(.horizontal, 6)
									.padding(.vertical, 2)
									.background(.red, in: Capsule())
									.padding(.bottom)
							}
						}
						Text(track.artists.formArtistString())
							.font(.headline)
							.padding(.bottom)
						if loadingState == .successful, let lyrics = lyrics {
							Group {
								if let syncedLines {
									VStack(alignment: .leading, spacing: 0) {
										ForEach(syncedLines.indices, id: \.self) { index in
											SyncedLyricsLineView(line: syncedLines[index], isActive: index == activeLine)
												.onTapGesture {
													player.seek(toSeconds: syncedLines[index].time)
												}
												.id(index)
												.onGeometryChange(for: Bool.self) { geometry in
													guard let scrollViewBounds = geometry.bounds(of: .scrollView) else {
														return false
													}
													return scrollViewBounds.contains(CGRect(origin: .zero, size: geometry.size))
												} action: { isFullyVisible in
													if isFullyVisible {
														fullyVisibleLines.insert(index)
													} else {
														fullyVisibleLines.remove(index)
													}
												}
										}
									}
								} else {
									Text(lyrics)
								}
							}
							.contextMenu {
								Button {
									logger.debug("Copy Lyrics")
									Pasteboard.copy(string: lyrics)
								} label: {
									Text("Copy")
								}
							}
						} else if loadingState == .loading {
							FullscreenLoadingSpinner(.loading)
						} else {
							Text("No Lyrics available")
								.foregroundStyle(.secondary)
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
			.onChange(of: activeLine) {
				if let activeLine, !fullyVisibleLines.contains(activeLine) {
					withAnimation {
						proxy.scrollTo(activeLine, anchor: .center)
					}
				}
			}
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
			syncedLines = nil
			player.setLyricsLineTimes([])
			loadingState = .error
			return
		}
		loadingState = .loading
		player.setLyricsLineTimes([])
		let response = await track.getLyrics(session: session)
		lyrics = response?.lyrics
		syncedLines = response?.syncedLines
		player.setLyricsLineTimes(syncedLines?.map(\.time) ?? [])
		loadingState = lyrics == nil ? .error : .successful
	}
}

// Separate view, so SwiftUI only re-evaluates the lines whose state changed
private struct SyncedLyricsLineView: View {
	let line: SyncedLyricsLine
	let isActive: Bool
	
	var body: some View {
		// An empty line would collapse, but it marks a break in the song
		Text(line.text.isEmpty ? " " : line.text)
			.fontWeight(isActive ? .bold : .regular)
			.frame(maxWidth: .infinity, alignment: .leading)
			.contentShape(Rectangle())
	}
}
