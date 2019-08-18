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
	var session: Session
	var album: Album
	
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
							Text(album.title)
								.font(.title)
								.lineLimit(2)
							Text("(i)")
								.foregroundColor(.gray)
							Text("<3")
								.foregroundColor(.gray)
						}
						Text(album.artists?.formArtistString() ?? "")
						if album.releaseDate != nil {
							Text(DateFormatter.dateOnly.string(from: album.releaseDate!))
						}
					}
					Spacer()
						.layoutPriority(-1)
					VStack(alignment: .leading) {
						if album.numberOfTracks != nil {
							Text("\(album.numberOfTracks!) Tracks")
							.foregroundColor(.gray)
						}
						if album.duration != nil {
							Text("\(album.duration!) sec")
							.foregroundColor(.gray)
						}
						Spacer()
					}
				}
				.frame(height: 100)
				
//				List(session.getAlbumTracks(albumId: album.id)!) { track in
//					TrackRow(track: track)
//				}
				

				ScrollView {
					HStack {
						VStack(alignment: .leading) {
							ForEach(session.getAlbumTracks(albumId: album.id)!) {track in
								TrackRowFront(track: track)
							}
						}
//							.background(Color.red)
						VStack(alignment: .trailing) {
							ForEach(session.getAlbumTracks(albumId: album.id)!) {track in
								TrackRowBack(track: track)
							}
						}
//							.background(Color.green)
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
					let url = self.album.getCoverUrl(session: self.session, resolution: 1280)
					if url != nil {
						let im = ImageLoader.load(url: url!)
						self.image = im
					}
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
