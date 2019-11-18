//
//  MyMixes.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 27.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct MyMixes: View {
	let session: Session
	let player: Player
	
	let mixes: [MixesItem]?
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		
		self.mixes = session.getMixes()
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("My Mixes")
				.font(.largeTitle)
				.padding(.horizontal)
			
			if mixes != nil {
				MixGrid(mixes: mixes!, session: session, player: player)
			} else {
				Text("Problems fetching Mixes")
					.font(.largeTitle)
			}
		}
	}
}

struct MixGrid: View {
	let mixes: [MixesItem]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(mixes) { mix in
			MixGridItem(mix: mix, session: self.session, player: self.player)
		}
		.gridStyle(
			AutoColumnsGridStyle(minItemWidth: 165, itemHeight: 230, hSpacing: 5, vSpacing: 5)
		)
			.padding()
	}
}

struct MixGridItem: View {
	let mix: MixesItem
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			MixImage(mix: mix, session: session)
				.frame(width: 160, height: 160)
				.cornerRadius(CORNERRADIUS)
				.shadow(radius: SHADOWRADIUS, y: SHADOWY)
			
			Text(mix.title)
				.frame(width: 160)
			Text(mix.subTitle)
				.fontWeight(.light)
				.foregroundColor(Color.secondary)
				.lineLimit(1)
				.frame(width: 160)
		}
		.padding(5)
		.onTapGesture(count: 2) {
			print("Second Click. \(self.mix.title)")
			if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
				self.player.add(tracks: tracks, .now)
				self.player.play()
			}
		}
		.onTapGesture(count: 1) {
			print("First Click. \(self.mix.title)")
			self.viewState.push(mix: self.mix)
		}
		.contextMenu {
			MixContextMenu(mix: mix, session: session, player: player)
		}
	}
}

struct MixPlaylistView: View {
	let mix: MixesItem?
	let session: Session
	let player: Player
	
	let tracks: [Track]?
	
	@EnvironmentObject var viewState: ViewState
	
	init(mix: MixesItem?, session: Session, player: Player) {
		self.mix = mix
		self.session = session
		self.player = player
		
		if let mix = mix {
			self.tracks = session.getMixPlaylistTracks(mixId: mix.id)
		} else {
			self.tracks = nil
		}
	}
	
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
				if mix == nil {
					HStack {
						Spacer()
					}
					Spacer()
				} else {
					HStack {
						MixImage(mix: mix!, session: session)
							.frame(width: 100, height: 100)
							.cornerRadius(CORNERRADIUS)
							.shadow(radius: SHADOWRADIUS, y: SHADOWY)
							.onTapGesture {
								let controller = CoverWindowController(rootView:
									URLImageSourceView(
										self.mix!.graphic.images[0].getImageUrl(session: self.session, resolution: 320)!,
										isAnimationEnabled: true,
										label: Text(self.mix!.title)
									)
								)
								controller.window?.title = self.mix!.title
								controller.showWindow(nil)
						}
						
						VStack(alignment: .leading) {
							Text(mix!.title)
								.font(.title)
								.lineLimit(2)
							Text(mix!.subTitle)
								.foregroundColor(.secondary)
						}
						Spacer(minLength: 0)
							.layoutPriority(-1)
					}
					.frame(height: 100)
					.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
					Divider()
					
					TrackList(tracks: tracks!, showCover: true, showAlbumTrackNumber: false,
							  showArtist: true, showAlbum: true, playlist: nil,
							  session: session, player: player)
				}
			}
		}
	}
}

struct MixImage: View {
	let mix: MixesItem
	let session: Session
	
	@State var scrollImages = false
	
	var body: some View {
		GeometryReader { metrics in
			if self.mix.graphic.images.count >= 5 {
				ZStack {
					VStack {
						HStack {
							Text(self.mix.title)
								.font(.system(size: metrics.size.width * 0.1))
								.bold()
								.foregroundColor(Color(hex: self.mix.graphic.images[0].vibrantColor)!)
								.padding(metrics.size.width * 0.1)
							Spacer()
						}
						Spacer()
					}
					
					// Animated Images
					VStack {
						HStack {
							// 4
							URLImageSourceView(
								self.mix.graphic.images[4].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							// 0 1
							URLImageSourceView(
								self.mix.graphic.images[0].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[1].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							
							// 2 3 4
							URLImageSourceView(
								self.mix.graphic.images[2].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[3].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[4].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							
							// 0 1
							URLImageSourceView(
								self.mix.graphic.images[0].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[1].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							Spacer()
								.frame(width: metrics.size.width * 0.2)
						}
						HStack {
							Spacer()
								.frame(width: metrics.size.width * 0.2)
							// 2 3 4
							URLImageSourceView(
								self.mix.graphic.images[2].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(.trailing, metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[3].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[4].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							
							// 0 1
							URLImageSourceView(
								self.mix.graphic.images[0].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[1].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							
							// 2 3 4
							URLImageSourceView(
								self.mix.graphic.images[2].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[3].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							URLImageSourceView(
								self.mix.graphic.images[4].getImageUrl(session: self.session, resolution: 160)!,
								isAnimationEnabled: true,
								label: Text(self.mix.title)
							)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
						}
					}
					.padding(metrics.size.width * 0.06)
					.offset(x: self.scrollImages ? metrics.size.width * -2.7 : metrics.size.width * -0.35)
					.rotationEffect(Angle(degrees: -12))
					.position(CGPoint(x: metrics.size.width * 2, y: metrics.size.width * 0.4))
					.scaleEffect(1)
					.animation(Animation.linear(duration: 10).repeatForever(autoreverses: false))
					.onAppear {
						self.scrollImages.toggle()
					}
				}
				.contentShape(Rectangle())
				.clipped()
				.overlay(
					RoundedRectangle(cornerRadius: CORNERRADIUS)
						.stroke(Color(hex: self.mix.graphic.images[0].vibrantColor)!, lineWidth: metrics.size.width * 0.1)
				)
					.background(Color(hex: self.mix.graphic.images[0].vibrantColor)!.colorMultiply(Color.gray))
			} else {
				Rectangle()
					.foregroundColor(Color.black)
			}
		}
	}
}

struct MixContextMenu: View {
	let mix: MixesItem
	let session: Session
	let player: Player
	
	@EnvironmentObject var playlistEditingValues: PlaylistEditingValues
	
	var body: some View {
		Group {
			Button(action: {
				if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
					self.player.add(tracks: tracks, .now)
				}
			}) {
				Text("Play Now")
			}
			Button(action: {
				if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
					self.player.add(tracks: tracks, .next)
				}
			}) {
				Text("Play Next")
			}
			Button(action: {
				if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
					self.player.add(tracks: tracks, .last)
				}
			}) {
				Text("Play Last")
			}
			Divider()
			Button(action: {
				print("Add \(self.mix.title) to Playlist")
				if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
					self.playlistEditingValues.tracks = tracks
					self.playlistEditingValues.showAddTracksModal = true
				}
			}) {
				Text("Add to Playlist …")
			}
			Divider()
			Button(action: {
				print("Download")
				if let tracks = self.session.getMixPlaylistTracks(mixId: self.mix.id) {
					_ = self.session.helpers?.download(tracks: tracks, parentFolder: self.mix.title)
				}
			}) {
				Text("Download")
			}
		}
	}
}


// MARK: - Color Extension

extension Color {
	public init?(hex: String) {
		let r, g, b, a: Double
		
		if hex.hasPrefix("#") {
			let start = hex.index(hex.startIndex, offsetBy: 1)
			let hexColor = String(hex[start...])
			
			if hexColor.count == 8 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0
				
				if scanner.scanHexInt64(&hexNumber) {
					r = Double((hexNumber & 0xff000000) >> 24) / 255
					g = Double((hexNumber & 0x00ff0000) >> 16) / 255
					b = Double((hexNumber & 0x0000ff00) >> 8) / 255
					a = Double(hexNumber & 0x000000ff) / 255
					
					self.init(red: r, green: g, blue: b, opacity: a)
					return
				}
			} else if hexColor.count == 6 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0
				
				if scanner.scanHexInt64(&hexNumber) {
					r = Double((hexNumber & 0xff0000) >> 16) / 255
					g = Double((hexNumber & 0x00ff00) >> 8) / 255
					b = Double(hexNumber & 0x0000ff) / 255
					
					self.init(red: r, green: g, blue: b)
					return
				}
			}
		}
		
		return nil
	}
}


//struct MyMixes_Previews: PreviewProvider {
//    static var previews: some View {
//        MyMixes()
//    }
//}
