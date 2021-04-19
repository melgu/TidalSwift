//
//  Video.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum VideoOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case dateAdded = "DATE"
	case length = "LENGTH"
}

extension Session {
	public func getVideo(videoId: Int) -> Video? {
		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Track Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var videoResponse: Video?
		do {
			videoResponse = try customJSONDecoder().decode(Video.self, from: content)
		} catch {
			displayError(title: "Track Info Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return videoResponse
	}
}
