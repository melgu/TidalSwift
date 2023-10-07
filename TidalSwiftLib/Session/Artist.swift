//
//  Artist.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public typealias ArtistOrder = PlaylistOrder

extension Session {
	public func artist(artistId: Int) async -> Artist? {
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)")!
		do {
			let response: Artist = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public enum ArtistAlbumFilter: String {
		case epsAndSingles = "EPSANDSINGLES"
		case appearances = "COMPILATIONS" // No idea, why Tidal has wrong names
	}
	
	public func artistAlbums(artistId: Int, filter: ArtistAlbumFilter? = nil, order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil, limit: Int = 999, offset: Int = 0) async -> [Album]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		if let filter = filter {
			parameters["filter"] = "\(filter.rawValue)"
		}
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/albums")!
		do {
			let response: Albums = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func artistVideos(artistId: Int, limit: Int = 999, offset: Int = 0) async -> [Video]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/videos")!
		do {
			let response: Videos = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func artistTopTracks(artistId: Int, limit: Int = 999, offset: Int = 0) async -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/toptracks")!
		do {
			let response: Tracks = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	func artistBio(artistId: Int, linksRemoved: Bool = true) async -> ArtistBio? {
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/bio")!
		do {
			let response: ArtistBio = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			
			// <br/> to \n
			let regex = #/<br/><br/>|<br/>/#
			var alteredText = response.text.replacing(regex, with: "\n\n")
			
			if linksRemoved {
				let regex = #/(\[wimpLink.+?\])|(\[\/wimpLink\])/#
				let range = NSMakeRange(0, alteredText.count)
				alteredText.replace(regex, with: "")
			}
			
			return ArtistBio(source: response.source, lastUpdated: response.lastUpdated, text: alteredText)
		} catch {
			return nil
		}
	}
	
	public func artistSimilar(artistId: Int) async -> [Artist]? {
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/similar")!
		do {
			let response: Artists = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func artistRadio(artistId: Int) async -> [Track]? {
		let url = URL(string: "\(AuthInformation.APILocation)/artists/\(artistId)/radio")!
		do {
			let response: Tracks = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
}
