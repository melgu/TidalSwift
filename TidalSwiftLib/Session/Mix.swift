//
//  Mix.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func mixes() async -> [MixesItem]? {
		var parameters = sessionParameters
		parameters["deviceType"] = "DESKTOP"
		let url = URL(string: "\(AuthInformation.APILocation)/pages/my_collection_my_mixes")!
		do {
			let response: Mixes = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			
			// Filter out Video Mixes for now
			// TODO: Add support for Video Mixes
			let audioOnlyMixes = response.rows[0].modules[0].pagedList.items.filter { $0.mixType == .audio }
			
			return audioOnlyMixes
		} catch {
			return nil
		}
	}
	
	public func mixPlaylistTracks(mixId: String) async -> [Track]? {
		var parameters = sessionParameters
		parameters["mixId"] = "\(mixId)"
		parameters["deviceType"] = "DESKTOP"
		parameters["token"] = "\(config.apiToken)"
		
		let url = URL(string: "\(AuthInformation.APILocation)/pages/mix")!
		do {
			let response: Mix = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.rows[1].modules[0].pagedList?.items
		} catch {
			return nil
		}
	}
}
