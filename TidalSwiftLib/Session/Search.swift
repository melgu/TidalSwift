//
//  Search.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func search(for term: String, limit: Int = 50, offset: Int = 0) -> SearchResponse? {
		var parameters = sessionParameters
		parameters["query"] = term
		parameters["limit"] = String(limit)
		parameters["offset"] = String(offset)
		// Server-side limit of 300. Doesn't go higher (also limits totalNumberOfItems to 300.
		// Can potentially go higher using offset.
		
		let url = URL(string: "\(config.apiLocation)/search/")!
		let response = Network.get(url: url, parameters: parameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Search failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var searchResponse: SearchResponse
		do {
			let searchResult = try customJSONDecoder().decode(SearchResult.self, from: content)
			searchResponse = SearchResponse(artists: searchResult.artists.items,
											albums: searchResult.albums.items,
											playlists: searchResult.playlists.items,
											tracks: searchResult.tracks.items,
											videos: searchResult.videos.items,
											topHit: searchResult.topHit)
		} catch {
			displayError(title: "Search failed (JSON Parse Error)", content: "\(error)")
			return nil
		}
		
		return searchResponse
	}
}
