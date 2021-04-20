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
	public func getPlaylist(playlistId: String) -> Playlist? {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Playlist Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistResponse: Playlist?
		do {
			playlistResponse = try customJSONDecoder.decode(Playlist.self, from: content)
		} catch {
			displayError(title: "Playlist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistResponse
	}
	
	public func getPlaylistTracks(playlistId: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/playlists/\(playlistId)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Playlist Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistTracksResponse: Tracks?
		do {
			playlistTracksResponse = try customJSONDecoder.decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Playlist Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistTracksResponse?.items
	}
}
