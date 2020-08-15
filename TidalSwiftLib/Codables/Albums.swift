//
//  Album.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

struct Albums: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Album]
}

public enum AudioMode: String, Codable {
	case stereo = "STEREO"
	case mono = "MONO"
	case sony360RealityAudio = "SONY_360RA"
	case dolbyAtmos = "DOLBY_ATMOS"
}

public struct Album: Codable, Equatable, Identifiable, Hashable {
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
	public let audioModes: [AudioMode]?
	public let artist: Artist?
	public let artists: [Artist]?
	
	public var isCompilation: Bool {
		artist?.name == "Various Artists"
	}
	
	public func isInFavorites(session: Session) -> Bool? {
		session.favorites?.doFavoritesContainAlbum(albumId: id)
	}
	
	public func getCoverUrl(session: Session, resolution: Int) -> URL? {
		guard let cover = cover else { return nil }
		return session.getImageUrl(imageId: cover, resolution: resolution)
	}
	
	public func getCover(session: Session, resolution: Int) -> NSImage? {
		guard let cover = cover else { return nil }
		return session.getImage(imageId: cover, resolution: resolution)
	}
	
	public func isOffline(session: Session) -> Bool {
		session.helpers.offline.isAlbumOffline(album: self)
	}
	
	public func addOffline(session: Session) {
		session.helpers.offline.add(album: self)
	}
	
	public func removeOffline(session: Session) {
		session.helpers.offline.remove(album: self)
	}
	
	public func getCredits(session: Session) -> [Credit]? {
		session.getAlbumCredits(albumId: id)
	}
	
	public static func == (lhs: Album, rhs: Album) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

public struct Credit: Decodable, Identifiable {
	public var id: String { type }
	public let type: String
	public let contributors: [Contributor]
}

public struct Contributor: Decodable {
	public let id: Int?
	public let name: String
}

public enum AlbumSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case artists // Optional
	case releaseDate // Optional
	case duration // Optional
	case popularity // Optional
}

extension Array where Element == Album {
	public func sortedAlbums(by sorting: AlbumSorting) -> [Album] { // TODO: Add reversed parameter
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .artists:
			return self.sorted {
				($0.artists?.formArtistString().lowercased() ?? "zzzzzzzzzz", $0.title.lowercased()) <
					($1.artists?.formArtistString().lowercased() ?? "zzzzzzzzzz", $1.title.lowercased())
			}
		case .releaseDate:
			return self.sorted {
				($0.releaseDate ?? Date.distantPast, $0.title.lowercased()) <
					($1.releaseDate ?? Date.distantPast, $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration ?? 0, $0.title.lowercased()) <
					($1.duration ?? 0, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity ?? 0, $0.title.lowercased()) <
					($1.popularity ?? 0, $1.title.lowercased())
			}
		}
	}
}
