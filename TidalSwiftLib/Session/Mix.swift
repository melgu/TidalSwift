//
//  Mix.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func getMixes() -> [MixesItem]? {
		var parameters = sessionParameters
		parameters["deviceType"] = "DESKTOP"
		let url = URL(string: "\(config.apiLocation)/pages/my_collection_my_mixes")!
		let response = Network.get(url: url, parameters: parameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Mixes Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var mixesResponse: Mixes?
		do {
			mixesResponse = try customJSONDecoder().decode(Mixes.self, from: content)
		} catch {
			displayError(title: "Mixes Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		// Filter out Video Mixes for now
		// TODO: Add support for Video Mixes
		let audioOnlyMixes = mixesResponse?.rows[0].modules[0].pagedList.items.filter { $0.mixType == .audio }
		
		return audioOnlyMixes
	}
	
	public func getMixPlaylistTracks(mixId: String) -> [Track]? {
		var parameters = sessionParameters
		parameters["mixId"] = "\(mixId)"
		parameters["deviceType"] = "DESKTOP"
		parameters["token"] = "\(config.apiToken)"
		
		let url = URL(string: "\(config.apiLocation)/pages/mix")!
		let response = Network.get(url: url, parameters: parameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Mix Playlist Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var mixResponse: Mix?
		do {
			mixResponse = try customJSONDecoder().decode(Mix.self, from: content)
		} catch {
			displayError(title: "Mix Playlist Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return mixResponse?.rows[1].modules[0].pagedList?.items
	}
}
