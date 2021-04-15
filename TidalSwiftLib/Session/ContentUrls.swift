//
//  ContentUrls.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	func getAudioUrl(trackId: Int) -> URL? {
		var parameters = sessionParameters
		parameters["soundQuality"] = "\(config.quality.rawValue)"
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/\(config.urlType.rawValue)")!
		let response = Network.get(url: url, parameters: parameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Couldn't get Audio URL (HTTP Error)", content: "Track ID: \(trackId). Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var audioUrlResponse: AudioUrl?
		do {
			audioUrlResponse = try JSONDecoder().decode(AudioUrl.self, from: content)
		} catch {
			displayError(title: "Couldn't get Audio URL (JSON Parse Error)", content: "\(error)")
		}
//		print("""
//		Track ID: \(mediaUrlResponse?.trackId ?? -1),
//		Quality: \(mediaUrlResponse?.soundQuality.rawValue ?? ""),
//		Codec: \(mediaUrlResponse?.codec ?? "")
//		""")
		
		return audioUrlResponse?.url
	}
	
	func getVideoUrl(videoId: Int) -> URL? {
//		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)/offlineUrl")! // Only returns low quality video
		let url = URL(string: "\(config.apiLocation)/videos/\(videoId)/streamUrl")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Couldn't get Video URL (HTTP Error)", content: "Video ID: \(videoId). Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var videoUrlResponse: VideoUrl?
		do {
			videoUrlResponse = try JSONDecoder().decode(VideoUrl.self, from: content)
		} catch {
			displayError(title: "Couldn't get Video URL (JSON Parse Error)", content: "\(error)")
		}
		
		return videoUrlResponse?.url
	}
	
	var pathExtensionForCurrentQuality: String {
		switch config.quality {
		case .low, .high:
			return "m4a"
		case .hifi, .master:
			return "flac"
		}
	}
}
