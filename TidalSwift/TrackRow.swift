//
//  TrackRow.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct TrackRowFront: View {
	var track: Track
	var coverArtUrl: URL?
	
	@State var image = Image("Single Black Pixel")
	
	var body: some View {
		HStack {
			if coverArtUrl != nil {
				image
					.resizable()
					.frame(width: 30, height: 30)
					.onAppear {
						let im = ImageLoader.load(url: self.coverArtUrl!)
						self.image = im
				}
			}
			Text("\(track.trackNumber)")
				.fontWeight(.thin)
				.foregroundColor(.gray)
			Text(track.title)
		}
//			.foregroundColor(.white)
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
			.frame(height: 30)
		
	}
}

#if DEBUG
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
#endif
