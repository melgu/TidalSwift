//
//  Codables.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

enum AudioQuality: String, Decodable {
	case master = "HI_RES"
	case hifi = "LOSSLESS"
	case high = "HIGH"
	case low = "LOW"
}

struct LoginResponse: Decodable {
	let userId: Int
	let sessionId: String
	let countryCode: String
}

struct Subscription: Decodable {
	let validUntil: Date
	let status: String
	let subscription: SubscriptionType
	let highestSoundQuality: AudioQuality
	let premiumAccess: Bool
	let canGetTrial: Bool
	let paymentType: String
}

struct SubscriptionType: Decodable {
	let type: String
	let offlineGracePeriod: Int
}

struct AudioUrl: Decodable {
	let url: URL
	let trackId: Int
	let soundQuality: AudioQuality
	let encryptionKey: String
	let codec: String
}

struct VideoUrl: Decodable {
	let url: URL
	let videoQuality: String
}

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

struct Artist: Decodable, Equatable {
	let id: Int
	let name: String
	let url: URL?
	let picture: String?
	let popularity: Int?
	let type: String? // What role he/she played
	let banner: String?
	let relationType: String? // e.g. SIMILAR_ARTIST
	
	func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else {
			return nil
		}
		return session.getImage(imageId: picture, resolution: resolution)
	}
	
	static func == (lhs: Artist, rhs: Artist) -> Bool {
		return lhs.id == rhs.id
	}
}

struct ArtistBio: Decodable {
	let source: String
	let lastUpdated: Date
	let text: String
}

struct Album: Decodable, Equatable {
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
	let cover: String?
	let videoCover: String?
	let explicit: Bool?
	let upc: String?
	let popularity: Int?
	let audioQuality: AudioQuality?
	let surroundTypes: [String]?
	let artist: Artist?
	let artists: [Artist]?
	
	func getCoverUrl(session: Session, resolution: Int) -> URL? {
		guard let cover = cover else { return nil }
		return session.getImageUrl(imageId: cover, resolution: resolution)
	}
	
	func getCover(session: Session, resolution: Int) -> NSImage? {
		guard let cover = cover else { return nil }
		return session.getImage(imageId: cover, resolution: resolution)
	}
	
	func isCompilation(session: Session) -> Bool {
		return session.isAlbumCompilation(albumId: id)
	}
	
	static func == (lhs: Album, rhs: Album) -> Bool {
		return lhs.id == rhs.id
	}
}

enum PlaylistType: String, Decodable {
	case user = "USER"
	case editorial = "EDITORIAL"
	case artist = "ARTIST"
	// Haven't seen others yet
}

struct Playlist: Decodable, Equatable {
	let uuid: String
	let title: String
	let numberOfTracks: Int
	let numberOfVideos: Int
	let creator: PlaylistCreator
	let description: String?
	let duration: Int
	let lastUpdated: Date
	let created: Date
	let type: PlaylistType
	let publicPlaylist: Bool
	let url: URL
	let image: String
	let popularity: Int
	let squareImage: String?
	
	func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: squareImage ?? image, resolution: resolution)
	}
	
	func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: squareImage ?? image, resolution: resolution)
	}
	
	static func == (lhs: Playlist, rhs: Playlist) -> Bool {
		return lhs.uuid == rhs.uuid
	}
}

struct PlaylistCreator: Decodable {
	let id: Int?
	let name: String?
	let url: URL?
	let picture: String?
	let popularity: Int?
	
	func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else {
			return nil
		}
		return session.getImage(imageId: picture, resolution: resolution)
	}
}

struct Track: Decodable, Equatable {
	let id: Int
	let title: String
	let duration: Int
	let replayGain: Float
	let peak: Float?
	let allowStreaming: Bool
	let streamReady: Bool
	let streamStartDate: Date?
	let premiumStreamingOnly: Bool?
	let trackNumber: Int
	let volumeNumber: Int
	let version: String?
	let popularity: Int
	let copyright: String?
	let url: URL
	let isrc: String?
	let editable: Bool
	let explicit: Bool
	let audioQuality: AudioQuality?
	let surroundTypes: [String]?
	let artist: Artist?
	let artists: [Artist]
	let album: Album
	
	func getCoverUrl(session: Session, resolution: Int) -> URL? {
		return album.getCoverUrl(session: session, resolution: resolution)
	}
	
	func getCover(session: Session, resolution: Int) -> NSImage? {
		return album.getCover(session: session, resolution: resolution)
	}
	
	static func == (lhs: Track, rhs: Track) -> Bool {
		return lhs.id == rhs.id
	}
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
	let quality: String // Careful as video quality is different to audio quality
	let streamReady: Bool
	let streamStartDate: Date
	let allowStreaming: Bool
	let explicit: Bool
	let popularity: Int
	let type: String // e.g. Music Video
	let adsUrl: String?
	let adsPrePaywallOnly: Bool
	let artists: [Artist]
	let album: Album?
	
	func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: imageId, resolution: resolution)
	}
	
	func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: imageId, resolution: resolution)
	}
	
	static func == (lhs: Video, rhs: Video) -> Bool {
		return lhs.id == rhs.id
	}
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

struct User: Decodable {
	let id: Int
	let username: String
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
	
	func getPictureUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	func getPicture(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: picture, resolution: resolution)
	}
}

struct Mixes: Decodable {
	let selfLink: URL?
	let id: String
	let title: String
	let rows: [MixesModules]
}

struct MixesModules: Decodable {
	let modules: [MixesModule]
}

struct MixesModule: Decodable {
	let id: String
	let width: Int
	let title: String
	let pagedList: MixesPagedList
}

struct MixesPagedList: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [MixesItem]
	let dataApiPath: String
}

struct MixesItem: Decodable {
	let id: String
	let title: String
	let subTitle: String
	let graphic: MixesGraphic
}

enum MixesGraphicType: String, Decodable {
	case squaresGrid = "SQUARES_GRID"
}

struct MixesGraphic: Decodable {
	let type: MixesGraphicType
	let text: String
	let images: [MixesGraphicImage]
}

enum MixesGraphicImageType: String, Decodable {
	case artist = "ARTIST"
}

struct MixesGraphicImage: Decodable {
	let id: String
	let vibrantColor: String
	let type: MixesGraphicImageType
	
	func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: id, resolution: resolution)
	}
	
	func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: id, resolution: resolution)
	}
}

struct Mix: Decodable {
	let selfLink: URL?
	let id: String
	let title: String
	let rows: [MixModules]
	// Aufpassen, da unterschiedliche Modules
	// Das interessante, welche Tracks enthält, ist [1]
}

struct MixModules: Decodable {
	let modules: [MixModule]
}

struct MixModule: Decodable {
	let id: String
	let width: Int
	let title: String
	let pagedList: Tracks?
}

typealias Moods = Genres
typealias Mood = Genre

struct Genres: Decodable { // Also Moods
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

struct Genre: Decodable { // Also Mood
	let name: String
	let path: String
	let hasPlaylists: Bool
	let hasArtists: Bool
	let hasAlbums: Bool
	let hasTracks: Bool
	let hasVideos: Bool
	let image: String
	
	func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: image, resolution: resolution)
	}
	
	func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: image, resolution: resolution)
	}
}

struct FeaturedItems: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FeaturedItem]
}

enum FeaturedType: String, Decodable {
	case categoryPages = "CATEGORY_PAGES"
	case externalUrl = "EXTURL"
	case video = "VIDEO"
	case playlist = "PLAYLIST"
	case album = "ALBUM"
}

struct FeaturedItem: Decodable {
	let imageURL: URL
	let artifactId: String
	let type: FeaturedType
	let text: String
	let created: Date
	let header: String
	let subHeader: String
	let group: String
	let shortHeader: String
	let shortSubHeader: String
	let persistSessionId: Bool
	let standaloneHeader: String
	let imageId: String
	let featured: Bool
	let openExternal: Bool
	
	func getImageUrl(session: Session, resolution: Int, resolutionY: Int) -> URL? {
		return session.getImageUrl(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
	}
	
	func getImage(session: Session, resolution: Int, resolutionY: Int) -> NSImage? {
		return session.getImage(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
	}
}

// MARK: - Favorites

struct FavoriteArtists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteArtist]
}

struct FavoriteArtist: Decodable, Equatable {
	let created: Date
	let item: Artist
	
	static func == (lhs: FavoriteArtist, rhs: FavoriteArtist) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	static func == (lhs: FavoriteArtist, rhs: Artist) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	static func == (lhs: Artist, rhs: FavoriteArtist) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteAlbums: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteAlbum]
}

struct FavoriteAlbum: Decodable, Equatable {
	let created: Date
	let item: Album
	
	static func == (lhs: FavoriteAlbum, rhs: FavoriteAlbum) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	static func == (lhs: FavoriteAlbum, rhs: Album) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	static func == (lhs: Album, rhs: FavoriteAlbum) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteTracks: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteTrack]
}

struct FavoriteTrack: Decodable, Equatable {
	let created: Date
	let item: Track
	
	static func == (lhs: FavoriteTrack, rhs: FavoriteTrack) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	static func == (lhs: FavoriteTrack, rhs: Track) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	static func == (lhs: Track, rhs: FavoriteTrack) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteVideos: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteVideo]
}

struct FavoriteVideo: Decodable, Equatable {
	let created: Date
	let item: Video
	
	static func == (lhs: FavoriteVideo, rhs: FavoriteVideo) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	static func == (lhs: FavoriteVideo, rhs: Video) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	static func == (lhs: Video, rhs: FavoriteVideo) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoritePlaylists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoritePlaylist]
}

struct FavoritePlaylist: Decodable, Equatable {
	let created: Date
	let item: Playlist
	
	static func == (lhs: FavoritePlaylist, rhs: FavoritePlaylist) -> Bool {
		return lhs.item.uuid == rhs.item.uuid
	}
	
	static func == (lhs: FavoritePlaylist, rhs: Playlist) -> Bool {
		return lhs.item.uuid == rhs.uuid
	}
	
	static func == (lhs: Playlist, rhs: FavoritePlaylist) -> Bool {
		return lhs.uuid == rhs.item.uuid
	}
}

// MARK: - Artist String

func formArtistString(artists: [Artist]) -> String {
	var artistString: String = ""
	
	guard !artists.isEmpty else {
		return artistString
	}
	
	// First
	artistString += artists[0].name
	
	guard artists.count > 1 else {
		return artistString
	}
	
	// Middles
	if artists.count > 2 {
		for i in 1 ..< artists.count - 1 {
			artistString += ", \(artists[i].name)"
		}
	}
	
	// Last
	artistString += " & \(artists.last!.name)"
	
	return artistString
}

// MARK: - Date

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
