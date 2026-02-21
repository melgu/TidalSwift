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
	public func video(videoId: Int) async -> Video? {
		let url = URL(string: "\(AuthInformation.APILocation)/videos/\(videoId)")!
		do {
			let response: Video = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
}
