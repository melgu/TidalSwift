//
//  TrackList.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackList: View {
	let tracks: [Track]
	let showCover: Bool
	let showAlbumTrackNumber: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				ForEach(0..<tracks.count) { i in
					TrackRowFront(track: self.tracks[i], showCover: self.showCover, trackNumber: self.showAlbumTrackNumber ? nil : i, session: self.session)
						.onTapGesture(count: 2) {
							print("\(self.tracks[i].title)")
							self.player.add(tracks: self.tracks, .now)
							self.player.play(atIndex: i)
					}
					.contextMenu {
						TrackContextMenu(track: self.tracks[i], session: self.session, player: self.player)
					}
					Divider()
				}
			}
			VStack(alignment: .trailing) {
				ForEach(0..<tracks.count) { i in
					TrackRowBack(track: self.tracks[i], session: self.session)
						.onTapGesture(count: 2) {
							print("\(self.tracks[i].title)")
							self.player.add(tracks: self.tracks, .now)
							self.player.play(atIndex: i)
					}
					.contextMenu {
						TrackContextMenu(track: self.tracks[i], session: self.session, player: self.player)
					}
					Divider()
				}
			}
		}
	}
}

struct TrackRowFront: View {
	let track: Track
	let showCover: Bool
	let trackNumber: Int?
	let session: Session
	
	var coverUrl: URL? = nil
	
	init(track: Track, showCover: Bool = false, trackNumber: Int? = nil, session: Session) {
		self.track = track
		self.showCover = showCover
		if let trackNumber = trackNumber {
			self.trackNumber = trackNumber + 1 // To start counting from 1
		} else {
			self.trackNumber = nil
		}
		self.session = session
		
		if showCover {
			self.coverUrl = track.getCoverUrl(session: session, resolution: 80)
		}
	}
	
	var body: some View {
		HStack {
			if showCover {
				if coverUrl != nil {
					URLImageSourceView(
						coverUrl!,
						isAnimationEnabled: true,
						label: Text(track.title)
					)
						.frame(width: 30, height: 30)
						.cornerRadius(CORNERRADIUS)
				} else {
					Rectangle()
						.frame(width: 30, height: 30)
						.cornerRadius(CORNERRADIUS)
				}
			} else {
				Text("\(trackNumber ?? track.trackNumber)")
					.fontWeight(.thin)
					.foregroundColor(.secondary)
			}
			Text(track.title)
		}
//			.foregroundColor(.white)
			.padding()
			.frame(height: 30) // TODO: Is 40 no matter what when cover is shown. Why?
		
	}
}

struct TrackRowBack: View {
	var track: Track
	
	var session: Session
	
	@State var t: Bool = false
	
	var body: some View {
		HStack {
			Spacer()
//				.layoutPriority(-1)
			Text(secondsToHoursMinutesSecondsString(seconds: track.duration))
			Spacer()
//				.layoutPriority(-1)
			Group {
//				Text("+")
				Text("􀅴")
					.onTapGesture {
						let controller = ResizableWindowController(rootView:
							CreditsView(track: self.track, session: self.session)
						)
						controller.window?.title = "Credits – \(self.track.title)"
						controller.showWindow(nil)
				}
				if self.t || !self.t {
					if self.track.isInFavorites(session: session)! {
						Text("􀊵")
							.onTapGesture {
								print("Remove from Favorites")
								self.session.favorites!.removeTrack(trackId: self.track.id)
								self.t.toggle()
						}
					} else {
						Text("􀊴")
							.onTapGesture {
								print("Add to Favorites")
								self.session.favorites!.addTrack(trackId: self.track.id)
								self.t.toggle()
						}
					}
				}
			}
			.layoutPriority(1)
		}
//			.foregroundColor(.white)
			.padding()
			.frame(height: 30)
		
	}
}

//struct TrackRow_Previews: PreviewProvider {
//	static var previews: some View {
//		Group {
//			TrackRow()
//				.previewDisplayName("With Cover")
//			TrackRow()
//				.previewDisplayName("Without Cover")
//		}
//	}
//}
