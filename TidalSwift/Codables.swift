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

struct SubscriptionResponse: Decodable {
	let validUntil: Date
	let status: String
	let subscription: SubscriptionTypeResponse
	let highestSoundQuality: String
	let premiumAccess: Bool
	let canGetTrial: Bool
	let paymentType: String
}

struct SubscriptionTypeResponse: Decodable {
	let type: String
	let offlineGracePeriod: Int
}

struct MediaUrlResponse: Decodable {
	let url: URL
	let trackId: Int
	let soundQuality: String
	let encryptionKey: String
	let codec: String
}

// Section: Search

struct SearchResultArtistsResponse: Decodable {
	let limit: Int
	let offset: Int // Probably used when requesting with limit
	let totalNumberOfItems: Int
	let items: [SearchResultArtistResponse]
}

struct SearchResultAlbumsResponse: Decodable {
	let limit: Int
	let offset: Int // Probably used when requesting with limit
	let totalNumberOfItems: Int
	let items: [SearchResultAlbumResponse]
}

struct SearchResultPlaylistsResponse: Decodable {
	let limit: Int
	let offset: Int // Probably used when requesting with limit
	let totalNumberOfItems: Int
	let items: [SearchResultPlaylistResponse]
}

struct SearchResultTracksResponse: Decodable {
	let limit: Int
	let offset: Int // Probably used when requesting with limit
	let totalNumberOfItems: Int
	let items: [SearchResultTrackResponse]
}

struct SearchResultVideosResponse: Decodable {
	let limit: Int
	let offset: Int // Probably used when requesting with limit
	let totalNumberOfItems: Int
	let items: [SearchResultVideoResponse]
}

struct SearchResultArtistResponse: Decodable {
	let id: Int
	let name: String
	let url: URL?
	let picture: String?
	let popularity: Int?
	let type: String? // What role he/she played
}

struct SearchResultAlbumResponse: Decodable {
	let id: Int
	let title: String
	let duration: Int? // In Seconds
	let streamReady: Bool?
	let streamStartDate: Date?
	let allowStreaming: Bool?
	let numberOfTracks: Int?
	let numberOfVideos: Int?
	let numberOfVolumes: Int?
	let releaseDate: Date?
	let copyright: String?
	let url: URL?
	let cover: String
	let explicit: Bool?
	let popularity: Int?
	let audioQuality: String?
	let artists: [SearchResultArtistResponse]?
}

struct SearchResultPlaylistResponse: Decodable {
	let uuid: String
	let title: String
	let numberOfTracks: Int
	let numberOfVideos: Int
	let creator: SearchResultPlaylistCreatorResponse
	let description: String
	let duration: Int
	let lastUpdated: Date
	let created: Date
	let type: String // e.g. Editorial
	let publicPlaylist: Bool
	let url: URL
	let image: String
	let popularity: Int
	let squareImage: String?
}

struct SearchResultPlaylistCreatorResponse: Decodable {
	let id: Int?
	let name: String?
	let url: URL?
	let picture: String?
	let popularity: Int?
}

struct SearchResultTrackResponse: Decodable {
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
	let copyright: String?
	let url: URL
	let isrc: String
	let editable: Bool
	let explicit: Bool
	let audioQuality: String
	let artists: [SearchResultArtistResponse]
	let album: SearchResultAlbumResponse
}

struct SearchResultVideoResponse: Decodable {
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
	let artists: [SearchResultArtistResponse]
}

struct SearchResultTopHitResponse: Decodable {
	let value: SearchResultTopHitValueResponse
	let type: String
}

struct SearchResultTopHitValueResponse: Decodable {
	let id: Int?
	let uuid: String?
	let popularity: Int
}

struct SearchResultResponse: Decodable {
	let artists: SearchResultArtistsResponse
	let albums: SearchResultAlbumsResponse
	let playlists: SearchResultPlaylistsResponse
	let tracks: SearchResultTracksResponse
	let videos: SearchResultVideosResponse
	let topHit: SearchResultTopHitResponse?
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
