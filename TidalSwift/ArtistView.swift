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
	
	@State var artist: Artist?
	@State var albums: [Album]?
	@State var videos: [Video]?
	@State var topTracks: [Track]?
	
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	enum BottomSectionType {
		case albums
		case videos
	}
	
	@EnvironmentObject var viewState: ViewState
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
					Spacer()
				}
				if loadingState == .successful {
					HStack {
						if artist!.getPictureUrl(session: session, resolution: 320) != nil {
							URLImageSourceView(
								artist!.getPictureUrl(session: session, resolution: 320)!,
								isAnimationEnabled: true,
								label: Text(artist!.name)
							)
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								.onTapGesture {
									let controller = CoverWindowController(rootView:
										URLImageSourceView(
											self.artist!.getPictureUrl(session: self.session, resolution: 750)!,
											isAnimationEnabled: true,
											label: Text(self.artist!.name)
										)
									)
									controller.window?.title = self.artist!.name
									controller.showWindow(nil)
							}
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(artist!.name)
									.font(.title)
									.lineLimit(2)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											ArtistBioView(session: self.session, artist: self.artist!)
										)
										controller.window?.title = "Bio – \(self.artist!.name)"
										controller.showWindow(nil)
								}
								if t || !t {
									if artist!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeArtist(artistId: self.artist!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addArtist(artistId: self.artist!.id)
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
						TrackList(tracks: topTracks!, showCover: true, showAlbumTrackNumber: false,
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
						AlbumGrid(albums: albums!, showArtists: false, showReleaseDate: true, session: session, player: player)
					} else if bottomSectionType == .videos {
						VideoGrid(videos: videos!, showArtists: false, session: session, player: player)
					}
				} else if loadingState == .loading {
					LoadingSpinner()
				} else {
					Text("Problems fetching Artist")
						.font(.largeTitle)
				}
			}
//		}
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
			var tArtist: Artist?
			var tTopTracks: [Track]?
			var tAlbums: [Album]?
			var tVideos: [Video]?
			
			if let artist = self.artist {
				if artist.url == nil {
					print("Reloading Artist: \(artist.name)")
					tArtist = self.session.getArtist(artistId: artist.id)
				} else {
					tArtist = artist
				}
				tTopTracks = self.session.getArtistTopTracks(artistId: artist.id, limit: 30, offset: 0)
				tAlbums = self.session.getArtistAlbums(artistId: artist.id)
				tVideos = self.session.getArtistVideos(artistId: artist.id)
				
				if tTopTracks != nil && tAlbums != nil && tVideos != nil {
					DispatchQueue.main.async {
						self.artist = tArtist
						self.topTracks = tTopTracks
						self.albums = tAlbums
						self.videos = tVideos
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
}
