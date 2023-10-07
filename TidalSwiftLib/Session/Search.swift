//
//  Search.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func search(for term: String, limit: Int = 50, offset: Int = 0) async -> SearchResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		// Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300.
		// Can potentially go higher using offset.
		
		let url = URL(string: "\(AuthInformation.APILocation)/search/")!
		do {
			let response: SearchResult = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			
			return SearchResponse(
				artists: response.artists.items,
				albums: response.albums.items,
				playlists: response.playlists.items,
				tracks: response.tracks.items,
				videos: response.videos.items,
				topHit: response.topHit
			)
		} catch {
			return nil
		}
	}
}
