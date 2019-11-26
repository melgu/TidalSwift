//
//  ArtistView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct ArtistView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	enum BottomSectionType {
		case albums
		case videos
	}
	
	@State var bottomSectionType: BottomSectionType = .albums
	@State var t: Bool = false
	
	var body: some View {
//		ScrollView { // TODO: Comment back in, when Grid supports nesting inside a ScrollView
			VStack(alignment: .leading) {
				HStack {
					Button(action: {
						print("Back")
						self.viewState.pop()
					}) {
						Text("􀆉")
					}
					.padding(.leading, 10)
					Spacer(minLength: 0)
					LoadingSpinner()
				}
				
				if viewState.stack.last!.tracks != nil && viewState.stack.last!.albums != nil && viewState.stack.last!.videos != nil {
					HStack {
						if viewState.stack.last!.artist!.getPictureUrl(session: session, resolution: 320) != nil {
							URLImageSourceView(
								viewState.stack.last!.artist!.getPictureUrl(session: session, resolution: 320)!,
								isAnimationEnabled: true,
								label: Text(viewState.stack.last!.artist!.name)
							)
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								.onTapGesture {
									let controller = CoverWindowController(rootView:
										URLImageSourceView(
											self.viewState.stack.last!.artist!.getPictureUrl(session: self.session, resolution: 750)!,
											isAnimationEnabled: true,
											label: Text(self.viewState.stack.last!.artist!.name)
										)
									)
									controller.window?.title = self.viewState.stack.last!.artist!.name
									controller.showWindow(nil)
							}
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(viewState.stack.last!.artist!.name)
									.font(.title)
									.lineLimit(2)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											ArtistBioView(session: self.session, artist: self.viewState.stack.last!.artist!)
										)
										controller.window?.title = "Bio – \(self.viewState.stack.last!.artist!.name)"
										controller.showWindow(nil)
								}
								if t || !t {
									if viewState.stack.last!.artist!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeArtist(artistId: self.viewState.stack.last!.artist!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addArtist(artistId: self.viewState.stack.last!.artist!.id)
												self.t.toggle()
										}
									}
								}
							}
						}
						Spacer(minLength: 0)
							.layoutPriority(-1)
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
					Divider()
					
					ScrollView {
						TrackList(tracks: viewState.stack.last!.tracks!, showCover: true, showAlbumTrackNumber: false,
								  showArtist: true, showAlbum: true, playlist: nil,
								  session: session, player: player)
					}
					.frame(height: 200)
					
					HStack {
						Picker(selection: $bottomSectionType, label: Spacer(minLength: 0)) {
							Text("Albums").tag(BottomSectionType.albums)
							Text("Videos").tag(BottomSectionType.videos)
						}
						.pickerStyle(SegmentedPickerStyle())
						.padding(.horizontal)
					}
					if bottomSectionType == .albums {
						AlbumGrid(albums: viewState.stack.last!.albums!, showArtists: false, showReleaseDate: true, session: session, player: player)
					} else if bottomSectionType == .videos {
						VideoGrid(videos: viewState.stack.last!.videos!, showArtists: false, session: session, player: player)
					}
				}
				Spacer(minLength: 0)
			}
//		}
	}
}
