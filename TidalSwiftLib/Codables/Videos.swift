//
//  Video.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

struct Videos: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Video]
}

public struct Video: Codable, Equatable, Identifiable, Hashable {
	public let id: Int
	public let title: String
	public let volumeNumber: Int
	public let trackNumber: Int
	public let releaseDate: Date
	public let imagePath: String? // As far as I know always null
	public let imageId: String?
	public let duration: Int
	public let quality: String // Careful as video quality is different to audio quality
	public let streamReady: Bool
	public let streamStartDate: Date?
	public let allowStreaming: Bool
	public let explicit: Bool
	public let popularity: Int
	public let type: String // e.g. Music Video
	public let adsUrl: String?
	public let adsPrePaywallOnly: Bool
	public let artists: [Artist]
//	public let album: Album? // Sometimes Tidal returns empty object here which breaks things. In all other cases I found, returns nil otherwise, so doesn't matter anyways.
	
	public func isInFavorites(session: Session) -> Bool? {
		session.favorites?.doFavoritesContainVideo(videoId: id)
	}
	
	public func getVideoUrl(session: Session) -> URL? {
		session.getVideoUrl(videoId: id)
	}
	
	public func getImageUrl(session: Session, resolution: Int) -> URL? {
		guard let imageId = imageId else {
			return nil
		}
		return session.getImageUrl(imageId: imageId, resolution: resolution)
	}
	
	public func getImage(session: Session, resolution: Int) -> NSImage? {
		guard let imageId = imageId else {
			return nil
		}
		return session.getImage(imageId: imageId, resolution: resolution)
	}
	
	public static func == (lhs: Video, rhs: Video) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct VideoUrl: Decodable {
	let url: URL
	let videoQuality: String
}

public enum VideoSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case artists
	case releaseDate
	case duration
	case popularity
}

extension Array where Element == Video {
	public func sortedVideos(by sorting: VideoSorting) -> [Video] {
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .artists:
			return self.sorted {
				($0.artists.formArtistString().lowercased(), $0.title.lowercased()) <
					($1.artists.formArtistString().lowercased(), $1.title.lowercased())
			}
		case .releaseDate:
			return self.sorted {
				($0.releaseDate, $0.title.lowercased()) <
					($1.releaseDate, $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration, $0.title.lowercased()) <
					($1.duration, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity, $0.title.lowercased()) <
					($1.popularity, $1.title.lowercased())
			}
		}
	}
}
