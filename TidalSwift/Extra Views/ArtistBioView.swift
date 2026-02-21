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
	let session: Session
	
	@State var artist: Artist
	@State var bio: ArtistBio?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
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
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
					}
					.contextMenu {
						Button {
							print("Copy Artist Bio")
							Pasteboard.copy(string: bio.text)
						} label: {
							Text("Copy")
						}
					}
				} else if loadingState == .loading {
					FullscreenLoadingSpinner(.loading)
				} else {
					Text("No Bio available")
						.foregroundColor(.secondary)
					Spacer(minLength: 0)
				}
				
			}
			.padding()
		}
		.onAppear {
			workItem = createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
		}
		.onDisappear {
			workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		DispatchWorkItem {
			Task {
				let t = await artist.bio(session: session)
				await MainActor.run {
					if let t {
						bio = t
						loadingState = .successful
					} else {
						loadingState = .error
					}
				}
			}
		}
	}
}
