//
//  ContentUrls.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	func audioUrl(trackId: Int, audioQuality: AudioQuality) async -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(audioQuality.rawValue)"
		let url = URL(string: "\(AuthInformation.APILocation)/tracks/\(trackId)/\(config.urlType.rawValue)")!
		do {
			let response: AudioUrl = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			
//			print("""
//			Track ID: \(response.trackId),
//			Quality: \(response.soundQuality.rawValue),
//			Codec: \(response.codec)
//			""")
			
			return response.url.upgradedToHTTPS
		} catch {
			return nil
		}
	}
	
	// FIXME: Currently uses the old API which returns HTTP-Calls inside the M3U manifest
	// This breaks video playback in conjunction with sandboxing
	func videoUrl(videoId: Int) async -> URL? {
//		let url = URL(string: "\(AuthInformation.APILocation)/videos/\(videoId)/offlineUrl")! // Only returns low quality video
		let url = URL(string: "\(AuthInformation.APILocation)/videos/\(videoId)/streamUrl")!
		do {
			let response: VideoUrl = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.url.upgradedToHTTPS
		} catch {
			return nil
		}
	}
	
	func pathExtension(for audioQuality: AudioQuality) -> String {
		switch audioQuality {
		case .low, .high:
			return "m4a"
		case .hifi, .master:
			return "flac"
		}
	}
}

private extension URL {
	var upgradedToHTTPS: URL {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
		guard components.scheme?.lowercased() == "http" else { return self }
		components.scheme = "https"
		return components.url ?? self
	}
}
