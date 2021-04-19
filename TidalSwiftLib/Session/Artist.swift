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
	public func getArtist(artistId: Int) -> Artist? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Artist Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistResponse: Artist?
		do {
			artistResponse = try customJSONDecoder().decode(Artist.self, from: content)
		} catch {
			displayError(title: "Artist Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistResponse
	}
	
	public enum ArtistAlbumFilter: String {
		case epsAndSingles = "EPSANDSINGLES"
		case appearances = "COMPILATIONS" // No idea, why Tidal has wrong names
	}
	
	public func getArtistAlbums(artistId: Int, filter: ArtistAlbumFilter? = nil, order: AlbumOrder? = nil,
						 orderDirection: OrderDirection? = nil, limit: Int = 999, offset: Int = 0) -> [Album]? {
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
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/albums")!
		let response = Network.get(url: url, parameters: parameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Artist Albums failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistAlbumsResponse: Albums?
		do {
			artistAlbumsResponse = try customJSONDecoder().decode(Albums.self, from: content)
		} catch {
			displayError(title: "Artist Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistAlbumsResponse?.items
	}
	
	public func getArtistVideos(artistId: Int, limit: Int = 999, offset: Int = 0) -> [Video]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/videos")!
		let response = Network.get(url: url, parameters: parameters, authorization: config.authorization, xTidalToken: config.apiToken)

		guard let content = response.content else {
			displayError(title: "Artist Videos failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistVideosResponse: Videos?
		do {
			artistVideosResponse = try customJSONDecoder().decode(Videos.self, from: content)
		} catch {
			displayError(title: "Artist Videos failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistVideosResponse?.items
	}
	
	public func getArtistTopTracks(artistId: Int, limit: Int = 999, offset: Int = 0) -> [Track]? {
		var parameters = sessionParameters
		parameters["limit"] = "\(limit)"
		parameters["offset"] = "\(offset)"
		
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/toptracks")!
		let response = Network.get(url: url, parameters: parameters, authorization: config.authorization, xTidalToken: config.apiToken)

		guard let content = response.content else {
			displayError(title: "Artist Top Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistTopTracksResponse: Tracks?
		do {
			artistTopTracksResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Artist Top Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistTopTracksResponse?.items
	}
	
	func getArtistBio(artistId: Int, linksRemoved: Bool = true) -> ArtistBio? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/bio")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Artist Bio failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistBio: ArtistBio?
		do {
			artistBio = try customJSONDecoder().decode(ArtistBio.self, from: content)
		} catch {
			displayError(title: "Artist Bio failed (JSON Parse Error)", content: "\(error)")
		}
		
		guard let ab = artistBio else {
			return nil
		}
		
		// <br/> to \n
		let regex = try! NSRegularExpression(pattern: #"<br/><br/>|<br/>"#)
		let range = NSMakeRange(0, ab.text.count)
		var alteredText = regex.stringByReplacingMatches(in: ab.text, options: [], range: range, withTemplate: "\n\n")
		
		if linksRemoved {
			let regex = try! NSRegularExpression(pattern: #"(\[wimpLink.+?\])|(\[\/wimpLink\])"#)
			let range = NSMakeRange(0, alteredText.count)
			alteredText = regex.stringByReplacingMatches(in: alteredText, options: [], range: range, withTemplate: "")
		}
		
		return ArtistBio(source: ab.source, lastUpdated: ab.lastUpdated, text: alteredText)
	}
	
	public func getArtistSimilar(artistId: Int) -> [Artist]? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/similar")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Similar Artists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var similarArtistsResponse: Artists?
		do {
			similarArtistsResponse = try customJSONDecoder().decode(Artists.self, from: content)
		} catch {
			displayError(title: "Similar Artists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return similarArtistsResponse?.items
	}
	
	public func getArtistRadio(artistId: Int) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/artists/\(artistId)/radio")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Artist Radio failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var artistRadioResponse: Tracks?
		do {
			artistRadioResponse = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Artist Radio failed (JSON Parse Error)", content: "\(error)")
		}
		
		return artistRadioResponse?.items
	}
}
