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
	let track: Track
	let showCover: Bool
	let trackNumber: Int?
	let session: Session
	
	init(track: Track, showCover: Bool = false, trackNumber: Int? = nil, session: Session) {
		self.track = track
		self.showCover = showCover
		self.trackNumber = trackNumber
		self.session = session
	}
	
	var body: some View {
		HStack {
			if showCover {
//				Rectangle()
				URLImageSourceView(
					track.getCoverUrl(session: session, resolution: 80)!,
					isAnimationEnabled: true,
					label: Text(track.title)
				)
//					.size(width: 30, height: 30)
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
			.frame(height: 30) // TODO: Is 40 no matter what when cover is shown. Why?
		
	}
}

struct TrackRowBack: View {
	var track: Track
	
	var body: some View {
		HStack {
//			Rectangle()
//				.frame(width: 30, height: 30)
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
