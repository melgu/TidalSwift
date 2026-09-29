//
//  TidalLinks.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 29.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

extension ViewState {
	/// The URL the Share button of the current view copies, if it has one
	var currentShareUrl: URL? {
		switch stack.last?.viewType {
		case .artist:
			stack.last?.artist?.url
		case .album:
			stack.last?.album?.url
		case .playlist:
			stack.last?.playlist?.url
		default:
			nil
		}
	}
	
	/// Opens the view for a link. Tracks open their album.
	func open(_ link: TidalLink) {
		Task {
			if await !push(link) {
				print("Couldn't load \(link)")
				#if canImport(AppKit)
				NSSound.beep()
				#endif
			}
		}
	}
	
	private func push(_ link: TidalLink) async -> Bool {
		switch link {
		case .track(let id):
			guard let track = await session.track(trackId: id) else { return false }
			push(album: track.album)
		case .album(let id):
			guard let album = await session.album(albumId: id) else { return false }
			push(album: album)
		case .artist(let id):
			guard let artist = await session.artist(artistId: id) else { return false }
			push(artist: artist)
		case .playlist(let uuid):
			guard let playlist = await session.playlist(playlistId: uuid) else { return false }
			push(playlist: playlist)
		}
		return true
	}
}
