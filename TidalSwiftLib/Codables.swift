//
//  Codables.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

public enum AudioQuality: String, Decodable {
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

public struct Subscription: Decodable {
	public let validUntil: Date
	public let status: String
	public let subscription: SubscriptionType
	public let highestSoundQuality: AudioQuality
	public let premiumAccess: Bool
	public let canGetTrial: Bool
	public let paymentType: String
}

public struct SubscriptionType: Decodable {
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

public struct Artist: Decodable, Equatable {
	public let id: Int
	public let name: String
	public let url: URL?
	public let picture: String?
	public let popularity: Int?
	public let type: String? // What role he/she played
	public let banner: String?
	public let relationType: String? // e.g. SIMILAR_ARTIST
	
	public func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	public func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else {
			return nil
		}
		return session.getImage(imageId: picture, resolution: resolution)
	}
	
	public static func == (lhs: Artist, rhs: Artist) -> Bool {
		return lhs.id == rhs.id
	}
}

public struct ArtistBio: Decodable {
	public let source: String
	public let lastUpdated: Date
	public let text: String
}

public struct Album: Decodable, Equatable, Identifiable {
	public let id: Int
	public let title: String
	public let duration: Int? // In Seconds
	public let streamReady: Bool?
	public let streamStartDate: Date?
	public let allowStreaming: Bool?
	public let premiumStreamingOnly: Bool?
	public let numberOfTracks: Int?
	public let numberOfVideos: Int?
	public let numberOfVolumes: Int?
	public let releaseDate: Date?
	public let copyright: String?
	public let type: String?
	public let version: String?
	public let url: URL?
	public let cover: String?
	public let videoCover: String?
	public let explicit: Bool?
	public let upc: String?
	public let popularity: Int?
	public let audioQuality: AudioQuality?
	public let surroundTypes: [String]?
	public let artist: Artist?
	public let artists: [Artist]?
	
	public func getCoverUrl(session: Session, resolution: Int) -> URL? {
		guard let cover = cover else { return nil }
		return session.getImageUrl(imageId: cover, resolution: resolution)
	}
	
	public func getCover(session: Session, resolution: Int) -> NSImage? {
		guard let cover = cover else { return nil }
		return session.getImage(imageId: cover, resolution: resolution)
	}
	
	public func isCompilation(session: Session) -> Bool {
		return session.isAlbumCompilation(albumId: id)
	}
	
	public static func == (lhs: Album, rhs: Album) -> Bool {
		return lhs.id == rhs.id
	}
}

public enum PlaylistType: String, Decodable {
	case user = "USER"
	case editorial = "EDITORIAL"
	case artist = "ARTIST"
	// Haven't seen others yet
}

public struct Playlist: Decodable, Equatable, Identifiable {
	public var id: String { uuid }
	
	public let uuid: String
	public let title: String
	public let numberOfTracks: Int
	public let numberOfVideos: Int
	public let creator: PlaylistCreator
	public let description: String?
	public let duration: Int
	public let lastUpdated: Date
	public let created: Date
	public let type: PlaylistType
	public let publicPlaylist: Bool
	public let url: URL
	public let image: String
	public let popularity: Int
	public let squareImage: String?
	
	public func getImageUrl(session: Session, resolution: Int, resolutionY: Int? = nil) -> URL? {
		if let resolutionY = resolutionY {
			return session.getImageUrl(imageId: squareImage ?? image, resolution: resolution, resolutionY: resolutionY)
		}
		
		if let squareImage = squareImage {
			return session.getImageUrl(imageId: squareImage, resolution: resolution)
		} else {
			return session.getImageUrl(imageId: image, resolution: 480, resolutionY: 320)
		}
	}
	
	public func getImage(session: Session, resolution: Int, resolutionY: Int? = nil) -> NSImage? {
		if let resolutionY = resolutionY {
			return session.getImage(imageId: squareImage ?? image, resolution: resolution, resolutionY: resolutionY)
		}
		
		if let squareImage = squareImage {
			return session.getImage(imageId: squareImage, resolution: resolution)
		} else {
			return session.getImage(imageId: image, resolution: 480, resolutionY: 320)
		}
	}
	
	public static func == (lhs: Playlist, rhs: Playlist) -> Bool {
		return lhs.uuid == rhs.uuid
	}
}

public struct PlaylistCreator: Decodable {
	let id: Int?
	let name: String?
	let url: URL?
	let picture: String?
	let popularity: Int?
	
	public func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	public func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else {
			return nil
		}
		return session.getImage(imageId: picture, resolution: resolution)
	}
}

public struct Track: Decodable, Equatable, Identifiable {
	public let id: Int
	public let title: String
	public let duration: Int
	public let replayGain: Float
	public let peak: Float?
	public let allowStreaming: Bool
	public let streamReady: Bool
	public let streamStartDate: Date?
	public let premiumStreamingOnly: Bool?
	public let trackNumber: Int
	public let volumeNumber: Int
	public let version: String?
	public let popularity: Int
	public let copyright: String?
	public let url: URL
	public let isrc: String?
	public let editable: Bool
	public let explicit: Bool
	public let audioQuality: AudioQuality?
	public let surroundTypes: [String]?
	public let artist: Artist?
	public let artists: [Artist]
	public let album: Album
	
	public func getCoverUrl(session: Session, resolution: Int) -> URL? {
		return album.getCoverUrl(session: session, resolution: resolution)
	}
	
	public func getCover(session: Session, resolution: Int) -> NSImage? {
		return album.getCover(session: session, resolution: resolution)
	}
	
	public func getAudioUrl(session: Session) -> URL? {
		return session.getAudioUrl(trackId: id)
	}
	
	public static func == (lhs: Track, rhs: Track) -> Bool {
		return lhs.id == rhs.id
	}
}

public struct Video: Decodable, Equatable, Identifiable {
	public let id: Int
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
	
	public func getVideoUrl(session: Session) -> URL? {
		return session.getVideoUrl(videoId: id)
	}
	
	public func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: imageId, resolution: resolution)
	}
	
	public func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: imageId, resolution: resolution)
	}
	
	public static func == (lhs: Video, rhs: Video) -> Bool {
		return lhs.id == rhs.id
	}
}

public struct TopHit: Decodable {
	public let value: TopHitValue
	public let type: String
}

public struct TopHitValue: Decodable {
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

struct FavoritesResponse: Decodable {
	let updatedFavoriteArtists: Date?
	let updatedFavoriteTracks: Date?
	let updatedFavoritePlaylists: Date?
	let updatedFavoriteAlbums: Date?
	let updatedPlaylists: Date?
	let updatedVideoPlaylists: Date?
	let updatedFavoriteVideos: Date?
}

public struct User: Decodable {
	public let id: Int
	public let username: String
	public let firstName: String
	public let lastName: String
	public let email: String
	public let countryCode: String
	public let created: Date
	public let picture: String
	public let newsletter: Bool
	public let acceptedEULA: Bool
	public let gender: String
	public let dateOfBirth: Date
	public let facebookUid: Int
	
	public func getPictureUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	public func getPicture(session: Session, resolution: Int) -> NSImage? {
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

public struct MixesItem: Decodable {
	public let id: String
	public let title: String
	public let subTitle: String
	public let graphic: MixesGraphic
}

public enum MixesGraphicType: String, Decodable {
	case squaresGrid = "SQUARES_GRID"
}

public struct MixesGraphic: Decodable {
	public let type: MixesGraphicType
	public let text: String
	public let images: [MixesGraphicImage]
}

public enum MixesGraphicImageType: String, Decodable {
	case artist = "ARTIST"
}

public struct MixesGraphicImage: Decodable {
	public let id: String
	public let vibrantColor: String
	public let type: MixesGraphicImageType
	
	public func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: id, resolution: resolution)
	}
	
	public func getImage(session: Session, resolution: Int) -> NSImage? {
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
public typealias Mood = Genre

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

public struct Genre: Decodable, Identifiable { // Also Mood
	public var id: String { name }
	
	let name: String
	let path: String
	let hasPlaylists: Bool
	let hasArtists: Bool
	let hasAlbums: Bool
	let hasTracks: Bool
	let hasVideos: Bool
	let image: String
	
	public func getImageUrl(session: Session, resolution: Int) -> URL? {
		return session.getImageUrl(imageId: image, resolution: resolution)
	}
	
	public func getImage(session: Session, resolution: Int) -> NSImage? {
		return session.getImage(imageId: image, resolution: resolution)
	}
}

struct FeaturedItems: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FeaturedItem]
}

public enum FeaturedType: String, Decodable {
	case categoryPages = "CATEGORY_PAGES"
	case externalUrl = "EXTURL"
	case video = "VIDEO"
	case playlist = "PLAYLIST"
	case album = "ALBUM"
}

public struct FeaturedItem: Decodable {
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
	
	public func getImageUrl(session: Session, resolution: Int, resolutionY: Int) -> URL? {
		return session.getImageUrl(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
	}
	
	public func getImage(session: Session, resolution: Int, resolutionY: Int) -> NSImage? {
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

public struct FavoriteArtist: Decodable, Equatable, Identifiable {
	public var id: Int { item.id }
	
	public let created: Date
	public let item: Artist
	
	public static func == (lhs: FavoriteArtist, rhs: FavoriteArtist) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteArtist, rhs: Artist) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Artist, rhs: FavoriteArtist) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteAlbums: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteAlbum]
}

public struct FavoriteAlbum: Decodable, Equatable, Identifiable {
	public var id: Int { item.id }
	
	public let created: Date
	public let item: Album
	
	public static func == (lhs: FavoriteAlbum, rhs: FavoriteAlbum) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteAlbum, rhs: Album) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Album, rhs: FavoriteAlbum) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteTracks: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteTrack]
}

public struct FavoriteTrack: Decodable, Equatable, Identifiable {
	public var id: Int { item.id }
	
	public let created: Date
	public let item: Track
	
	public static func == (lhs: FavoriteTrack, rhs: FavoriteTrack) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteTrack, rhs: Track) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Track, rhs: FavoriteTrack) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoriteVideos: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoriteVideo]
}

public struct FavoriteVideo: Decodable, Equatable, Identifiable {
	public var id: Int { item.id }
	
	public let created: Date
	public let item: Video
	
	public static func == (lhs: FavoriteVideo, rhs: FavoriteVideo) -> Bool {
		return lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteVideo, rhs: Video) -> Bool {
		return lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Video, rhs: FavoriteVideo) -> Bool {
		return lhs.id == rhs.item.id
	}
}

struct FavoritePlaylists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoritePlaylist]
}

public struct FavoritePlaylist: Decodable, Equatable {
	public var id: String { item.id }
	
	public let created: Date
	public let item: Playlist
	
	public static func == (lhs: FavoritePlaylist, rhs: FavoritePlaylist) -> Bool {
		return lhs.item.uuid == rhs.item.uuid
	}
	
	public static func == (lhs: FavoritePlaylist, rhs: Playlist) -> Bool {
		return lhs.item.uuid == rhs.uuid
	}
	
	public static func == (lhs: Playlist, rhs: FavoritePlaylist) -> Bool {
		return lhs.uuid == rhs.item.uuid
	}
}

// MARK: - Artist String

extension Array where Element == Artist {
	public func formArtistString() -> String {
		var artistString: String = ""
		let artists = self
		
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

extension DateFormatter {
	public static let dateOnly: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = DateFormatter.Style.long
		formatter.timeStyle = DateFormatter.Style.none
		return formatter
	}()
}
