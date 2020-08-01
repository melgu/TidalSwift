//
//  MixGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

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
			print("Second Click. \(mix.title)")
			if let tracks = session.getMixPlaylistTracks(mixId: mix.id) {
				player.add(tracks: tracks, .now)
				player.play()
			}
		}
		.onTapGesture(count: 1) {
			print("First Click. \(mix.title)")
			viewState.push(mix: mix)
		}
		.contextMenu {
			MixContextMenu(mix: mix, session: session, player: player)
		}
	}
}

struct MixImage: View {
	let mix: MixesItem
	let session: Session
	
	@State var scrollImages = false
	
	var body: some View {
		GeometryReader { metrics in
			if mix.graphic.images.count >= 5 {
				ZStack {
					VStack {
						HStack {
							Text(mix.title)
								.font(.system(size: metrics.size.width * 0.1))
								.bold()
								.foregroundColor(Color(hex: mix.graphic.images[0].vibrantColor) ?? Color.gray)
								.padding(metrics.size.width * 0.1)
							Spacer()
						}
						Spacer()
					}
					
					// Animated Images
					VStack {
						HStack {
							// 4
							if let imageUrl = mix.graphic.images[4].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							// 0 1
							if let imageUrl = mix.graphic.images[0].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[1].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							// 2 3 4
							if let imageUrl = mix.graphic.images[2].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[3].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[4].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							// 0 1
							if let imageUrl = mix.graphic.images[0].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[1].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							Spacer()
								.frame(width: metrics.size.width * 0.2)
						}
						HStack {
							Spacer()
								.frame(width: metrics.size.width * 0.2)
							
							// 2 3 4
							if let imageUrl = mix.graphic.images[2].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(.trailing, metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[3].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[4].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							// 0 1
							if let imageUrl = mix.graphic.images[0].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[1].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							
							// 2 3 4
							if let imageUrl = mix.graphic.images[2].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[3].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
							if let imageUrl = mix.graphic.images[4].getImageUrl(session: session, resolution: 160) {
								URLImageSourceView(
									imageUrl,
									isAnimationEnabled: true,
									label: Text(mix.title)
								)
								.frame(width: metrics.size.width * 0.4, height: metrics.size.width * 0.4)
								.padding(metrics.size.width * 0.01)
							}
						}
					}
					.padding(metrics.size.width * 0.06)
					.offset(x: scrollImages ? metrics.size.width * -2.7 : metrics.size.width * -0.35)
					.rotationEffect(Angle(degrees: -12))
					.position(CGPoint(x: metrics.size.width * 2, y: metrics.size.width * 0.4))
					.scaleEffect(1)
					.animation(Animation.linear(duration: 10).repeatForever(autoreverses: false))
					.onAppear {
						scrollImages.toggle()
					}
				}
				.contentShape(Rectangle())
				.clipped()
				.overlay(
					RoundedRectangle(cornerRadius: CORNERRADIUS)
						.stroke(Color(hex: mix.graphic.images[0].vibrantColor) ?? Color.gray, lineWidth: metrics.size.width * 0.1)
				)
				.background((Color(hex: mix.graphic.images[0].vibrantColor) ?? Color.gray).colorMultiply(Color.gray))
			} else {
				Rectangle()
					.foregroundColor(Color.black)
			}
		}
	}
}
