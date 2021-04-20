//
//  Track.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum TrackOrder: String {
	case name = "NAME"
	case artist = "ARTIST"
	case album = "ALBUM"
	case dateAdded = "DATE"
	case length = "LENGTH"
}

public enum AudioUrlType: String {
	case streaming = "streamUrl"
	case offline = "offlineUrl"
}

extension Session {
	public func getTrack(trackId: Int) -> Track? {
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Track Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var trackResponse: Track?
		do {
			trackResponse = try customJSONDecoder.decode(Track.self, from: content)
		} catch {
			displayError(title: "Track Info Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return trackResponse
	}
	
	public func getTrackCredits(trackId: Int) -> [Credit]? {
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/credits")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Track Credits Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var creditsResponse: [Credit]?
		do {
			creditsResponse = try customJSONDecoder.decode([Credit].self, from: content)
		} catch {
			displayError(title: "Track Credits Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return creditsResponse
	}
	
	// Delete inexistent or unaccessable Tracks from list
	// Detected by checking for nil values
	public func cleanTrackList(_ trackList: [Track]) -> [Track] {
		var result = [Track]()
		for track in trackList {
			if !(track.streamStartDate == nil || track.audioQuality == nil) {
				result.append(track)
			}
		}
		return result
	}
	
	public func getTrackRadio(trackId: Int, limit: Int = 100, offset: Int = 0) -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/tracks/\(trackId)/radio")!
		let response = Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Track Radio (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var trackRadioResponse: Tracks?
		do {
			trackRadioResponse = try customJSONDecoder.decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Track Radio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return trackRadioResponse?.items
	}
}
