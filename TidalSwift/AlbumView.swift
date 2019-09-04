//
//  AlbumView.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct AlbumView: View {
	let album: Album
	let session: Session
	
	@State var bigCover = false
	
	var body: some View {
		ZStack {
			VStack(alignment: .leading) {
				HStack {
					URLImageSourceView(
						album.getCoverUrl(session: session, resolution: 320)!,
						isAnimationEnabled: true,
						label: Text(album.title)
					)
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
				
				ScrollView {
					HStack {
						VStack(alignment: .leading) {
							ForEach(session.getAlbumTracks(albumId: album.id)!) { track in
								TrackRowFront(track: track, session: self.session)
							}
						}
//							.background(Color.red)
						VStack(alignment: .trailing) {
							ForEach(session.getAlbumTracks(albumId: album.id)!) { track in
								TrackRowBack(track: track)
							}
						}
//							.background(Color.green)
					}
				}
				
			}
			.blur(radius: bigCover ? 4 : 0)
			
			if bigCover {
				URLImageSourceView(
					album.getCoverUrl(session: session, resolution: 1280)!,
					isAnimationEnabled: true,
					label: Text(album.title)
				)
					.scaledToFit()
					.padding()
			}
			
			
		}
		.foregroundColor(.white)
		.padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
		.background(
			URLImageSourceView(
				album.getCoverUrl(session: session, resolution: 1280)!,
				isAnimationEnabled: true,
				label: Text(album.title)
			)
				.aspectRatio(contentMode: .fill)
				.scaleEffect(1.2)
				.brightness(-0.5)
				.blur(radius: 30)
		)
			.onTapGesture {
				self.bigCover = false
		}
	}
	
}

//struct AlbumView_Previews: PreviewProvider {
//
//	static var previews: some View {
//		AlbumView(session: getSession(), album: getAlbum())
////		.frame(width: 500, height: 300)
////			.environment(\.colorScheme, .light)
////		Group {
////			AlbumView()
////				.environment(\.colorScheme, .light)
////			AlbumView()
////				.environment(\.colorScheme, .dark)
////		}
//
//	}
//}
