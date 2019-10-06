//
//  VideoGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct VideoGrid: View {
	let videos: [Video]
	let showArtists: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(videos) { video in
			VideoGridItem(video: video, showArtist: self.showArtists, session: self.session, player: self.player)
		}
		.padding()
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 210, hSpacing: 5, vSpacing: 0)
		)
	}
}

struct VideoGridItem: View {
    let video: Video
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if video.getImageUrl(session: session, resolution: 320) != nil {
//				Rectangle()
				URLImageSourceView(
					video.getImageUrl(session: session, resolution: 320)!,
					isAnimationEnabled: true,
					label: Text(video.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
			} else {
				ZStack {
					Image("Single Black Pixel")
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: 160, height: 160)
					Text(video.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			Text(video.title)
				.lineLimit(1)
				.frame(width: 160)
			if showArtist {
				Text(video.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.gray)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("\(self.video.title)")
//			self.player.add(playlist: self.playlist, .now)
		}
	}
}

//struct VideoGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoGrid()
//    }
//}
