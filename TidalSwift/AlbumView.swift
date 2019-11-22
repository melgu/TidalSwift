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
	let session: Session
	let player: Player
	
	@State var album: Album?
	@State var tracks: [Track]?
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	@EnvironmentObject var viewState: ViewState
	@State var t: Bool = false
	
	var body: some View {
		ScrollView {
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
				if album != nil && tracks != nil {
					HStack {
						URLImageSourceView(
							album!.getCoverUrl(session: session, resolution: 320)!,
							isAnimationEnabled: true,
							label: Text(album!.title)
						)
							.frame(width: 100, height: 100)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
							.onTapGesture {
								let controller = CoverWindowController(rootView:
									URLImageSourceView(
										self.album!.getCoverUrl(session: self.session, resolution: 1280)!,
										isAnimationEnabled: true,
										label: Text(self.album!.title)
									)
								)
								controller.window?.title = self.album!.title
								controller.showWindow(nil)
						}
						
						VStack(alignment: .leading) {
							HStack {
								Text(album!.title)
									.font(.title)
									.lineLimit(2)
								Text("􀅴")
									.foregroundColor(.secondary)
									.onTapGesture {
										let controller = ResizableWindowController(rootView:
											CreditsView(session: self.session, album: self.album!)
										)
										controller.window?.title = "Credits – \(self.album!.title)"
										controller.showWindow(nil)
								}
								if t || !t {
									if album!.isInFavorites(session: session)! {
										Text("􀊵")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Remove from Favorites")
												self.session.favorites!.removeAlbum(albumId: self.album!.id)
												self.t.toggle()
										}
									} else {
										Text("􀊴")
											.foregroundColor(.secondary)
											.onTapGesture {
												print("Add to Favorites")
												self.session.favorites!.addAlbum(albumId: self.album!.id)
												self.t.toggle()
										}
									}
								}
							}
							Text(album!.artists?.formArtistString() ?? "")
							if album!.releaseDate != nil {
								Text(DateFormatter.dateOnly.string(from: album!.releaseDate!))
							}
						}
						Spacer()
							.layoutPriority(-1)
						VStack(alignment: .leading) {
							if album!.numberOfTracks != nil {
								Text("\(album!.numberOfTracks!) Tracks")
									.foregroundColor(.secondary)
							}
							if album!.duration != nil {
								Text(secondsToHoursMinutesSecondsString(seconds: album!.duration!))
									.foregroundColor(.secondary)
							}
							Spacer()
						}
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
					Divider()
					
					TrackList(tracks: tracks!, showCover: false, showAlbumTrackNumber: true,
							  showArtist: true, showAlbum: false, playlist: nil,
							  session: session, player: player)
				} else if loadingState == .loading {
					LoadingSpinner()
				} else {
					Text("Problems fetching album")
						.font(.largeTitle)
				}
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
			var tAlbum: Album?
			var tTracks: [Track]?
			if let album = self.album {
				if album.releaseDate == nil {
					print("Album incomplete. Loading complete album: \(album.title)")
					tAlbum = self.session.getAlbum(albumId: album.id)
				} else {
					tAlbum = self.album
				}
				tTracks = self.session.getAlbumTracks(albumId: album.id)
				
				if tTracks != nil {
					DispatchQueue.main.async {
						self.album = tAlbum
						self.tracks = tTracks
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
