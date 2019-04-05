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

struct Subscription: Decodable {
	let validUntil: Date
	let status: String
	let subscription: SubscriptionType
	let highestSoundQuality: String
	let premiumAccess: Bool
	let canGetTrial: Bool
	let paymentType: String
}

struct SubscriptionType: Decodable {
	let type: String
	let offlineGracePeriod: Int
}

struct MediaUrl: Decodable {
	let url: URL
	let trackId: Int
	let soundQuality: String
	let encryptionKey: String
	let codec: String
}

// Section: Search

struct Artists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Artist]
}

struct Albums: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Album]
}

struct Playlists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Playlist]
}

struct Tracks: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Track]
}

struct Videos: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Video]
}

struct Artist: Decodable {
	let id: Int
	let name: String
	let url: URL?
	let picture: String?
	let popularity: Int?
	let type: String? // What role he/she played
	let banner: String?
	let relationType: String? // e.g. SIMILAR_ARTIST
}

struct Album: Decodable {
	let id: Int
	let title: String
	let duration: Int? // In Seconds
	let streamReady: Bool?
	let streamStartDate: Date?
	let allowStreaming: Bool?
	let premiumStreamingOnly: Bool?
	let numberOfTracks: Int?
	let numberOfVideos: Int?
	let numberOfVolumes: Int?
	let releaseDate: Date?
	let copyright: String?
	let type: String?
	let version: String?
	let url: URL?
	let cover: String
	let videoCover: String?
	let explicit: Bool?
	let upc: String?
	let popularity: Int?
	let audioQuality: String?
	let surroundTypes: [String]?
	let artist: Artist?
	let artists: [Artist]?
}

struct Playlist: Decodable {
	let uuid: String
	let title: String
	let numberOfTracks: Int
	let numberOfVideos: Int
	let creator: PlaylistCreator
	let description: String
	let duration: Int
	let lastUpdated: Date
	let created: Date
	let type: String // e.g. EDITORIAL or USER
	let publicPlaylist: Bool
	let url: URL
	let image: String
	let popularity: Int
	let squareImage: String?
}

struct PlaylistCreator: Decodable {
	let id: Int?
	let name: String?
	let url: URL?
	let picture: String?
	let popularity: Int?
}

struct Track: Decodable {
	let id: Int
	let title: String
	let duration: Int
	let replayGain: Float
	let peak: Float
	let allowStreaming: Bool
	let streamReady: Bool
	let streamStartDate: Date
	let premiumStreamingOnly: Bool?
	let trackNumber: Int
	let volumeNumber: Int
	let version: String?
	let popularity: Int
	let copyright: String?
	let url: URL
	let isrc: String
	let editable: Bool
	let explicit: Bool
	let audioQuality: String
	let surroundTypes: [String]?
	let artist: Artist?
	let artists: [Artist]
	let album: Album
}

struct Video: Decodable {
	let id: Int
	let title: String
	let volumeNumber: Int
	let trackNumber: Int
	let releaseDate: Date
	let imagePath: String? // As far as I know always null
	let imageId: String
	let duration: Int
	let quality: String
	let streamReady: Bool
	let streamStartDate: Date
	let allowStreaming: Bool
	let explicit: Bool
	let popularity: Int
	let type: String // e.g. Music Video
	let adsUrl: String?
	let adsPrePaywallOnly: Bool
	let artists: [Artist]
}

struct TopHit: Decodable {
	let value: TopHitValue
	let type: String
}

struct TopHitValue: Decodable {
	let id: Int?
	let uuid: String?
	let popularity: Int
}

struct SearchResult: Decodable {
	let artists: Artists
	let albums: Albums
	let playlists: Playlists
	let tracks: Tracks
	let videos: Videos
	let topHit: TopHit?
}

struct FavoritesResponse: Decodable {
	let updatedFavoriteArtists: Date?
	let updatedFavoriteTracks: Date?
	let updatedFavoritePlaylists: Date?
	let updatedFavoriteAlbums: Date?
	let updatedPlaylists: Date?
	let updatedVideoPlaylists: Date?
	let updatedFavoriteVideos: Date?
}

struct ArtistBio: Decodable {
	let source: String
	let lastUpdated: Date
	let text: String
}

struct User: Decodable {
	let id: Int
	let userName: String
	let firstName: String
	let lastName: String
	let email: String
	let countryCode: String
	let created: Date
	let picture: String
	let newsletter: Bool
	let acceptedEULA: Bool
	let gender: String
	let dateOfBirth: Date
	let facebookUid: Int
}

struct Genres: Decodable {
	let items: [Genre]
	
	init(from decoder: Decoder) throws {
		var containersArray = try decoder.unkeyedContainer()
		var temp: [Genre] = []
		for _ in 0..<containersArray.count! {
			temp.append(try containersArray.decode(Genre.self))
		}
		items = temp
	}
}

struct Genre: Decodable {
	let name: String
	let path: String
	let hasPlaylists: Bool
	let hasArtists: Bool
	let hasAlbums: Bool
	let hasTracks: Bool
	let hasVideos: Bool
	let image: String
}


// Date

func customJSONDecoder() -> JSONDecoder {
	let decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601OptionalTime)
	return decoder
}

class OptionalTimeDateFormatter: DateFormatter {
	static let withoutTime: DateFormatter = {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.timeZone = TimeZone(identifier: "UTC")
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter
	}()
	
	func setup() {
		self.calendar = Calendar(identifier: .iso8601)
		self.timeZone = TimeZone(identifier: "UTC")
		self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
	}
	
	override init() {
		super.init()
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	override func date(from string: String) -> Date? {
		if let result = super.date(from: string) {
			return result
		}
		return OptionalTimeDateFormatter.withoutTime.date(from: string)
	}
}

extension DateFormatter {
	static let iso8601OptionalTime = OptionalTimeDateFormatter()
}
