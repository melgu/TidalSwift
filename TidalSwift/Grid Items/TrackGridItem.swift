//
//  TrackGridItem.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct TrackGridItem: View {
	let track: Track
	let showArtist: Bool
	let session: Session
	let player: Player
	
	var body: some View {
		VStack {
			if let coverUrl = track.album.getCoverUrl(session: session, resolution: 320) {
				URLImageSourceView(
					coverUrl,
					isAnimationEnabled: true,
					label: Text(track.title)
				)
					.aspectRatio(contentMode: .fit)
					.frame(width: 160, height: 160)
					.cornerRadius(CORNERRADIUS)
			} else {
				ZStack {
					Rectangle()
						.frame(width: 160, height: 160)
					Text(track.title)
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.lineLimit(5)
						.frame(width: 160)
				}
			}
			HStack {
				Text(track.title)
				if let version = track.version {
					Text(version)
						.foregroundColor(.secondary)
						.padding(.leading, -5)
				}
				track.attributeHStack
					.padding(.leading, -5)
					.layoutPriority(1)
			}
			.lineLimit(1)
			.frame(width: 160)
			if showArtist {
				Text(track.artists.formArtistString())
					.fontWeight(.light)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
					.frame(width: 160)
					.padding(.top, track.hasAttributes ? -6.5 : 0)
			}
		}
		.padding(5)
		.toolTip(toolTipString)
		.onTapGesture(count: 2) {
			print("\(track.title)")
			player.add(track: track, .now)
		}
		.contextMenu {
			TrackContextMenu(track: track, session: session, player: player)
		}
	}
	
	var toolTipString: String {
		var s = track.title
		if let version = track.version {
			s += " (\(version))"
		}
		s += track.artists.formArtistString()
		return s
	}
}

extension Track {
	var attributeHStack: some View {
		HStack {
			if explicit {
				Image("e.square")
			}
			if audioQuality == .master {
				Image("m.square.fill")
			} else if audioModes?.contains(.sony360RealityAudio) ?? false {
				Image("headphones")
			} else if audioModes?.contains(.dolbyAtmos) ?? false {
				Image("hifispeaker.fill")
			}
		}
		.secondaryIconColor()
	}
	
	var hasAttributes: Bool {
		explicit ||
			audioQuality == .master ||
			audioModes?.contains(.sony360RealityAudio) ?? false ||
			audioModes?.contains(.dolbyAtmos) ?? false
	}
	
	var isUnavailable: Bool {
		!streamReady ||
		audioModes?.contains(.sony360RealityAudio) ?? false ||
			audioModes?.contains(.dolbyAtmos) ?? false
	}
}
