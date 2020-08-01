//
//  Search.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public struct TopHit: Codable, Equatable {
	public let value: TopHitValue
	public let type: String
}

public struct TopHitValue: Codable, Equatable {
	public let id: Int?
	public let uuid: String?
	public let popularity: Int
}

struct SearchResult: Decodable {
	let artists: Artists
	let albums: Albums
	let playlists: Playlists
	let tracks: Tracks
	let videos: Videos
	let topHit: TopHit?
}

public struct SearchResponse: Codable, Equatable {
	public let artists: [Artist]
	public let albums: [Album]
	public let playlists: [Playlist]
	public let tracks: [Track]
	public let videos: [Video]
	public let topHit: TopHit?
}
