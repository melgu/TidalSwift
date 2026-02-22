//
//  MixPlaylistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct MixPlaylistView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading) {
					if let mix = viewState.stack.last?.mix, let tracks = viewState.stack.last?.tracks {
						HStack {
							MixImage(mix: mix, highResolutionImages: false, session: session)
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								#if canImport(AppKit)
								.onTapGesture {
									let controller = ResizableWindowControllerFactory.create(rootView: MixImage(mix: mix, highResolutionImages: true, session: session), width: 640, height: 640)
									controller.window?.title = mix.title
									controller.showWindow(nil)
								}
								#endif
							
							VStack(alignment: .leading) {
								Text(mix.title)
									.font(.title)
									.lineLimit(2)
								Text(mix.subTitle)
									.foregroundColor(.secondary)
							}
							Spacer(minLength: 0)
							LoadingSpinner()
						}
						.frame(height: 100)
						.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
						
						TrackList(wrappedTracks: tracks.wrapped(), showCover: true, showAlbumTrackNumber: false,
								  showArtist: true, showAlbum: true, playlist: nil,
								  session: session, player: player)
					}
					Spacer(minLength: 0)
				}
				.padding(.top, 40)
				
			}
			BackButton()
		}
	}
}

