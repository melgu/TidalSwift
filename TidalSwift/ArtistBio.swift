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
				} else if loadingState == .loading {
					FullscreenLoadingSpinner()
				} else {
					Text("No Bio available")
						.foregroundColor(.secondary)
					Spacer(minLength: 0)
				}
				
			}
			.padding()
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			let t = self.artist.bio(session: self.session)
			
			if t != nil {
				DispatchQueue.main.async {
					self.bio = t
					self.loadingState = .successful
				}
			} else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
			}
		}
	}
}
