//
//  Album.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum AlbumOrder: String {
	case dateAdded = "DATE"
	case name = "NAME"
	case artist = "ARTIST"
	case releaseDate = "RELEASE_DATE"
}

extension Session {
	public func getAlbum(albumId: Int) -> Album? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Album Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var albumResponse: Album?
		do {
			albumResponse = try customJSONDecoder().decode(Album.self, from: content)
		} catch {
			displayError(title: "Album Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumResponse
	}
	
	public func getAlbumTracks(albumId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Album Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var albumTracksResponse: Tracks?
		do {
			albumTracksResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Album Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return albumTracksResponse?.items
	}
	
	public func getAlbumCredits(albumId: Int) -> [Credit]? {
		let url = URL(string: "\(config.apiLocation)/albums/\(albumId)/credits")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Album Credits Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var creditsResponse: [Credit]?
		do {
			creditsResponse = try customJSONDecoder().decode([Credit].self, from: content)
		} catch {
			displayError(title: "Album Credits Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return creditsResponse
	}
}
