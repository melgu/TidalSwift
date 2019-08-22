//
//  TrackRow.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackRowFront: View {
	let session: Session
	let track: Track
	let showCover: Bool
	
	init(session: Session, track: Track, trackNumber: Int? = nil, showCover: Bool = false) {
		self.session = session
		self.track = track
		self.showCover = showCover
	}
	
	var body: some View {
		HStack {
			if showCover {
				URLImageSourceView(
					track.getCoverUrl(session: session, resolution: 80)!,
					isAnimationEnabled: true,
					label: Text(track.title)
				)
					.frame(width: 30, height: 30)
			} else {
				Text("\(track.trackNumber)")
					.fontWeight(.thin)
					.foregroundColor(.gray)
			}
			Text(track.title)
		}
//			.foregroundColor(.white)
			.padding()
			.frame(height: 30)
		
	}
}

struct TrackRowBack: View {
	var track: Track
	
	var body: some View {
		HStack {
			Spacer()
//				.layoutPriority(-1)
			Text("\(track.duration) sec")
			Spacer()
//				.layoutPriority(-1)
//			Text("^")
//				.foregroundColor(.gray)
			Group {
				Text("+")
				Text("<3")
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
