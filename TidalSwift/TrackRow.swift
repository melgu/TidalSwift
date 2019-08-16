//
//  TrackRow.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct TrackRow: View {
	var showCover: Bool
	
	@State var image = Image("Single Black Pixel")
	
	var body: some View {
		HStack {
			if showCover {
				image
					.resizable()
					.frame(width: 30, height: 30)
					.onAppear {
						let im = ImageLoader.load(url: "https://resources.tidal.com/images/e60d7380/2a14/4011/bbc1/a3a1f0c576d6/80x80.jpg")
						self.image = im
				}
			}
			Text("09")
				.fontWeight(.thin)
				.foregroundColor(.gray)
			Text("All Night Long")
			Spacer()
			Text("6:31")
			Spacer()
			Text("^")
				.foregroundColor(.gray)
			Text("+")
			Text("<3")
		}
//		.foregroundColor(.white)
		.frame(height: 30)
		
	}
}

#if DEBUG
struct TrackRow_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			TrackRow(showCover: true)
				.previewDisplayName("With Cover")
			TrackRow(showCover: false)
				.previewDisplayName("Without Cover")
		}
	}
}
#endif
