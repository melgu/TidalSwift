//
//  VideoGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct VideoGridItem: View {
	let video: Video
	let showArtist: Bool
	let session: Session
	let player: Player
	
	@EnvironmentObject var playbackInfo: PlaybackInfo
	
	var body: some View {
		VStack {
			if let imageUrl = video.getImageUrl(session: session, resolution: 320) {
				URLImageSourceView(
					imageUrl,
					isAnimationEnabled: false,
					label: Text(video.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
					.shadow(radius: SHADOWRADIUS, y: SHADOWY)
			} else {
				ZStack {
					Rectangle()
						.foregroundColor(.black)
						.frame(width: 160, height: 160)
						.cornerRadius(CORNERRADIUS)
						.shadow(radius: SHADOWRADIUS, y: SHADOWY)
					Text(video.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.frame(width: 160)
				}
			}
			HStack {
				Text(video.title)
					.lineLimit(1)
				if video.explicit {
					Text("􀂝")
						.foregroundColor(.secondary)
						.layoutPriority(1)
				}
			}
			.frame(width: 160)
			if showArtist {
				Text(video.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
			}
		}
		.padding(5)
		.toolTip("\(video.title) – \(video.artists.formArtistString())")
		.onTapGesture(count: 2) {
			print("Play Video: \(video.title)")
			guard let url = video.getVideoUrl(session: session) else {
				return
			}
			print(url)
			player.pause()
			let controller = VideoPlayerController(videoUrl: url, volume: playbackInfo.volume)
			controller.window?.title = "\(video.title) - \(video.artists.formArtistString())"
			controller.showWindow(nil)
		}
		.contextMenu {
			VideoContextMenu(video: video, session: session, player: player)
		}
	}
}
