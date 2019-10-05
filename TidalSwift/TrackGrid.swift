//
//  TrackGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackGridItem: View {
    let track: Track
		let session: Session
		let player: Player
		
		var body: some View {
			VStack {
				if track.album.getCoverUrl(session: session, resolution: 320) != nil {
	//				Rectangle()
					URLImageSourceView(
						track.album.getCoverUrl(session: session, resolution: 320)!,
						isAnimationEnabled: true,
						label: Text(track.title)
					)
						.aspectRatio(contentMode: .fit)
						.frame(width: 160, height: 160)
				} else {
					ZStack {
						Image("Single Black Pixel")
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 160, height: 160)
						Text(track.title)
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.frame(width: 160)
					}
				}
				Text(track.title)
					.frame(width: 160)
			}
			.padding(5)
			.onTapGesture(count: 2) {
				print("\(self.track.title)")
				self.player.add(track: self.track, .now)
			}
		}
}

//struct TrackGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackGrid()
//    }
//}
