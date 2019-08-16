//
//  AlbumView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AlbumView: View {@State var image = Image("Single Black Pixel")
	@State var bigCover = false
	
	var body: some View {
		ZStack {
			VStack(alignment: .leading) {
				HStack {
					image
						.resizable()
						.frame(width: 100, height: 100)
						.onTapGesture {
							self.bigCover.toggle()
					}
					
					VStack(alignment: .leading) {
						HStack {
							Text("Djesse Vol. 1")
								.font(.title)
								.lineLimit(2)
							Text("(i)")
								.foregroundColor(.gray)
							Text("<3")
								.foregroundColor(.gray)
						}
						Text("Jacob Collier")
						Text("2018")
					}
					Spacer()
					VStack(alignment: .leading) {
						Text("9 Titel")
							.foregroundColor(.gray)
						Text("53:16")
							.foregroundColor(.gray)
						Spacer()
					}
				}
				.frame(height: 100)
				
				ScrollView {
					ForEach(0 ..< 50) {_ in
						TrackRow(showCover: false)
					}
				}
				
			}
			.blur(radius: bigCover ? 4 : 0)
			
			if bigCover {
				image
					.resizable()
					.scaledToFit()
					.padding()
			}
			
			
		}
		.foregroundColor(.white)
		.padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
		.background(
			image
				.resizable()
				.aspectRatio(contentMode: .fill)
				.scaleEffect(1.2)
				.brightness(-0.5)
				.blur(radius: 30)
				.onAppear {
					let im = ImageLoader.load(url: "https://resources.tidal.com/images/e60d7380/2a14/4011/bbc1/a3a1f0c576d6/1280x1280.jpg")
					self.image = im
		})
			.onTapGesture {
				if self.bigCover {
					self.bigCover.toggle()
				}
		}
	}
	
}

#if DEBUG
//struct AlbumView_Previews: PreviewProvider {
//	
//	static var previews: some View {
//		AlbumView()
////		.frame(width: 500, height: 300)
//			.environment(\.colorScheme, .light)
////		Group {
////			AlbumView()
////				.environment(\.colorScheme, .light)
////			AlbumView()
////				.environment(\.colorScheme, .dark)
////		}
//		
//	}
//}
#endif
