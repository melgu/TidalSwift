//
//  ArtistBio.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import OSLog

private let logger = Logger(category: "ArtistBioView")

struct ArtistBioView: View {
	let session: Session
	
	@State var artist: Artist
	@State private var bio: ArtistBio?
	@State private var loadingState: LoadingState = .loading
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text(artist.name)
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				if let bio = bio {
					Group {
						Text(bio.text)
						Text("")
						Text("\(bio.source) – Last Updated: \(bio.lastUpdatedString)")
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
					}
					.contextMenu {
						Button {
							logger.debug("Copy Artist Bio")
							Pasteboard.copy(string: bio.text)
						} label: {
							Text("Copy")
						}
					}
				} else if loadingState == .loading {
					FullscreenLoadingSpinner(.loading)
				} else {
					Text("No Bio available")
						.foregroundStyle(.secondary)
					Spacer(minLength: 0)
				}
				
			}
			.padding()
		}
		.task(id: artist.id) {
			let t = await artist.bio(session: session)
			if let t {
				bio = t
				loadingState = .successful
			} else {
				loadingState = .error
			}
		}
	}
}
