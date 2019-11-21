//
//  ArtistBio.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ArtistBioView: View {
	let artist: Artist
	let bio: ArtistBio?
	
	init(artist: Artist, session: Session) {
		self.artist = artist
		self.bio = artist.bio(session: session)
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text(artist.name)
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				if bio != nil {
					Group {
						Text(bio!.text)
						Text("")
						Text("\(bio!.source) – Last Updated: \(bio!.lastUpdatedString)")
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
					}
					.contextMenu {
						if bio != nil {
							Button(action: {
								print("Copy")
								let pb = NSPasteboard.init(name: NSPasteboard.Name.general)
								pb.declareTypes([.string], owner: nil)
								pb.setString(self.bio!.text, forType: .string)
							}) {
								Text("Copy")
							}
						}
					}
				} else {
					Text("No Bio available")
						.foregroundColor(.secondary)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
