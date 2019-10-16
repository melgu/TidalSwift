//
//  PlaylistView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct PlaylistView: View {
	let playlist: Playlist?
	let session: Session
	let player: Player
	
	let tracks: [Track]?
	
	init(playlist: Playlist?, session: Session, player: Player) {
		self.playlist = playlist
		self.session = session
		self.player = player
		
		if let playlist = playlist {
			self.tracks = session.getPlaylistTracks(playlistId: playlist.id)
		} else {
			self.tracks = nil
		}
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if playlist == nil {
					HStack {
						Spacer()
					}
					Spacer()
				} else {
					HStack {
						URLImageSourceView(
							playlist!.getImageUrl(session: session, resolution: 320)!,
							isAnimationEnabled: true,
							label: Text(playlist!.title)
						)
							.frame(width: 100, height: 100)
						
						VStack(alignment: .leading) {
							HStack {
								Text(playlist!.title)
									.font(.title)
									.lineLimit(2)
								Text("(i)")
									.foregroundColor(.secondary)
								Text("<3")
									.foregroundColor(.secondary)
							}
							Text(playlist!.creator.name ?? "")
							Text(DateFormatter.dateOnly.string(from: playlist!.lastUpdated))
						}
						Spacer()
							.layoutPriority(-1)
						VStack(alignment: .leading) {
							Text("\(playlist!.numberOfTracks) Tracks")
								.foregroundColor(.secondary)
							Text("\(playlist!.duration) sec")
								.foregroundColor(.secondary)
							Spacer()
						}
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
					Divider()
					
					
					TrackList(tracks: tracks!, showCover: true, session: session, player: player)
				}
			}
		}
	}
}

//struct PlaylistView_Previews: PreviewProvider {
//	static var previews: some View {
//		PlaylistView()
//	}
//}
