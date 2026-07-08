//
//  Playlist.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum PlaylistOrder: String {
	case dateAdded = "DATE"
	case name = "NAME"
}

extension Session {
	public func playlist(playlistId: String) async -> Playlist? {
		let url = URL(string: "\(AuthInformation.APILocation)/playlists/\(playlistId)")!
		do {
			let response: Playlist = try await get(url: url, parameters: sessionParameters)
			return response
		} catch {
			return nil
		}
	}
	
	public func playlistTracks(playlistId: String) async -> [Track]? {
		let url = URL(string: "\(AuthInformation.APILocation)/playlists/\(playlistId)/tracks")!
		do {
			let response: Tracks = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}
}
