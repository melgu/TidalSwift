//
//  Album.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum AlbumOrder: String {
	case dateAdded = "DATE"
	case name = "NAME"
	case artist = "ARTIST"
	case releaseDate = "RELEASE_DATE"
}

extension Session {
	public func album(albumId: Int) async -> Album? {
		let url = URL(string: "\(AuthInformation.APILocation)/albums/\(albumId)")!
		do {
			let response: Album = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public func albumTracks(albumId: Int) async -> [Track]? {
		let url = URL(string: "\(AuthInformation.APILocation)/albums/\(albumId)/tracks")!
		do {
			let response: Tracks = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func albumCredits(albumId: Int) async -> [Credit]? {
		let url = URL(string: "\(AuthInformation.APILocation)/albums/\(albumId)/credits")!
		do {
			let response: [Credit] = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
}
