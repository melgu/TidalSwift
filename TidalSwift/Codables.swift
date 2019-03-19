//
//  Codables.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

struct LoginResponse: Decodable {
	let userId: Int
	let sessionId: String
	let countryCode: String
}

struct MediaUrlResponse: Decodable {
	let url: String
	let trackId: Int
	let soundQuality: String
	let encryptionKey: String
	let codec: String
}

// Section: Search

struct SearchResultResponseArtists: Decodable {
	let totalNumberOfItems: Int
	let items: [SearchResultResponseArtist]
}

struct SearchResultResponseAlbums: Decodable {
	let totalNumberOfItems: Int
	let items: [SearchResultResponseArtist]
}

struct SearchResultResponsePlaylists: Decodable {
	let totalNumberOfItems: Int
	let items: [SearchResultResponseArtist]
}

struct SearchResultResponseTracks: Decodable {
	let totalNumberOfItems: Int
	let items: [SearchResultResponseArtist]
}

struct SearchResultResponseVideos: Decodable {
	let totalNumberOfItems: Int
	let items: [SearchResultResponseArtist]
}

struct SearchResultResponseArtist: Decodable {
	let id: Int
	let name: String
	let url: String?
	let picture: String?
	let popularity: Int?
	let type: String? // What role he/she played
}

struct SearchResultResponseAlbum: Decodable {
	let id: Int
	let title: String
	let duration: Int?
	let streamReady: Bool?
	let streamStartDate: Date?
	let allowStreaming: Bool?
	let numberOfTracks: Int?
	let numberOfVideos: Int?
	let numberOfVolumes: Int?
	let releaseDate: Date?
	let copyright: String?
	let url: String?
	let cover: String
	let explicit: Bool?
	let popularity: Int?
	let audioQuality: String?
	let artists: SearchResultResponseArtists?
}

struct SearchResultResponsePlaylist: Decodable {
	let uuid: Int
	let title: String
	let numberOfTracks: Int
	let numberOfVideos: Int
	let creator: String
	let description: String
	let duration: Int
	let lastUpdated: Date
	let created: Date
	let type: String // e.g. Editorial
	let publicPlaylist: Bool
	let url: String
	let image: String
	let popularity: Int
	let squareImage: String
}

struct SearchResultResponseTrack: Decodable {
	let id: Int
	let title: String
	let duration: Int
	let replayGain: Float
	let peak: Float
	let allowStreaming: Bool
	let streamReady: Bool
	let streamStartDate: Date
	let trackNumber: Int
	let volumeNumber: Int
	let popularity: Int
	let copyright: String
	let url: String
	let isrc: String
	let editable: Bool
	let explicit: Bool
	let audioQuality: String
	let artists: SearchResultResponseArtists
	let album: SearchResultResponseAlbum
}

struct SearchResultResponseVideo: Decodable {
	let id: Int
	let title: String
	let volumeNumber: Int
	let trackNumber: Int
	let releaseDate: Date
	//	let imagePath: String // Maybe use it at later stage if necessary
	let imageId: String
	let duration: Int
	let quality: String
	let streamReady: Bool
	let streamStartDate: Date
	let allowStreaming: Bool
	let explicit: Bool
	let popularity: Int
	let type: String // e.g. Music Video
	let artists: [SearchResultResponseArtist]
}

struct SearchResultResponseTopHit: Decodable {
	let value: [String: String]
	let type: String
	// TODO: Can be different type (artist, album...)
}

struct SearchResultResponse: Decodable {
	let artists: SearchResultResponseArtists
	let albums: SearchResultResponseAlbums
	let playlists: SearchResultResponsePlaylists
	let tracks: SearchResultResponseTracks
	let videos: SearchResultResponseVideos
	let topHit: SearchResultResponseTopHit
}
