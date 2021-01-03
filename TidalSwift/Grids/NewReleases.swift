//
//  NewReleases.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

struct NewReleases: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	@State var cancellable: AnyCancellable?
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("New Releases")
						.font(.largeTitle)
					Spacer()
					LoadingSpinner()
					Toggle("Include EPs and Singles", isOn: $viewState.newReleasesIncludeEps)
				}
				
				if let albums = viewState.stack.last?.albums {
					AlbumGrid(albums: albums, showArtists: true, showReleaseDate: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding(.horizontal)
		}
		.onAppear {
			cancellable = viewState.$newReleasesIncludeEps
				.sink { _ in
					viewState.refreshCurrentView()
				}
		}
		.onDisappear {
			cancellable?.cancel()
		}
	}
}
