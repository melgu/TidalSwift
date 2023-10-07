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
	public func track(trackId: Int) async -> Track? {
		let url = URL(string: "\(AuthInformation.APILocation)/tracks/\(trackId)")!
		do {
			let response: Track = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public func trackCredits(trackId: Int) async -> [Credit]? {
		let url = URL(string: "\(AuthInformation.APILocation)/tracks/\(trackId)/credits")!
		do {
			let response: [Credit] = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
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
	
	public func trackRadio(trackId: Int, limit: Int = 100, offset: Int = 0) async -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(AuthInformation.APILocation)/tracks/\(trackId)/radio")!
		do {
			let response: Tracks = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
}
