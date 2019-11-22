//
//  NewReleases.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Grid

struct NewReleases: View {
	let session: Session
	let player: Player
	
	@State var albums: [Album]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("New Releases")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if albums != nil {
				AlbumGrid(albums: albums!, showArtists: true, showReleaseDate: true, session: session, player: player)
			} else if loadingState == .loading {
				LoadingSpinner()
			} else {
				Text("Problems fetching favorite albums")
					.font(.largeTitle)
			}
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
			let t = self.session.helpers?.newReleasesFromFavoriteArtists(number: 40)
			DispatchQueue.main.async {
				if t != nil {
					self.albums = t
					self.loadingState = .successful
				} else {
					self.loadingState = .error
				}
			}
		}
	}
}
