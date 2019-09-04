//
//  Playlist.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct PlaylistView: View {
	let playlist: Playlist
	let session: Session
	
	@State var bigCover = false
	
	var body: some View {
		ZStack {
			VStack(alignment: .leading) {
				HStack {
					Rectangle()
//					URLImageSourceView(
//						playlist.getImageUrl(session: session, resolution: 320)!,
//						isAnimationEnabled: true,
//						label: Text(playlist.title)
//					)
						.frame(width: 100, height: 100)
						.onTapGesture {
							self.bigCover.toggle()
					}
					
					VStack(alignment: .leading) {
						HStack {
							Text(playlist.title)
								.font(.title)
								.lineLimit(2)
							Text("(i)")
								.foregroundColor(.gray)
							Text("<3")
								.foregroundColor(.gray)
						}
						Text("Album Artists")
						Text(DateFormatter.dateOnly.string(from: playlist.lastUpdated))
					}
					Spacer()
						.layoutPriority(-1)
					VStack(alignment: .leading) {
						Text("\(playlist.numberOfTracks) Tracks")
							.foregroundColor(.gray)
						Text("\(playlist.duration) sec")
							.foregroundColor(.gray)
						Spacer()
					}
				}
				.frame(height: 100)
				
				ScrollView {
					HStack {
						VStack(alignment: .leading) {
							ForEach(session.getPlaylistTracks(playlistId: playlist.id)!) { track in
								TrackRowFront(track: track, session: self.session)
							}
						}
//							.background(Color.red)
						VStack(alignment: .trailing) {
							ForEach(session.getPlaylistTracks(playlistId: playlist.id)!) { track in
								TrackRowBack(track: track)
							}
						}
//							.background(Color.green)
					}
				}
			}
			
			if bigCover {
				Rectangle()
//				URLImageSourceView(
//					playlist.getImageUrl(session: session, resolution: 1280)!,
//					isAnimationEnabled: true,
//					label: Text(playlist.title)
//				)
					.scaledToFit()
					.padding()
			}
		}
	}
}

//struct PlaylistView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlaylistView()
//	}
//}
