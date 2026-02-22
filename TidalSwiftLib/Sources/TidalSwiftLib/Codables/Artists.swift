//
//  Artist.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

struct Artists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Artist]
}

public enum ArtistType: String, Codable {
	case artist = "ARTIST"
	case contributor = "CONTRIBUTOR"
}

public struct Artist: Codable, Equatable, Identifiable, Hashable {
	public let id: Int
	public let name: String
	public let artistTypes: Set<ArtistType>?
	public let url: URL?
	public let picture: String?
	public let popularity: Int?
	public let type: String? // What role he/she played
	public let banner: String?
	public let relationType: String? // e.g. SIMILAR_ARTIST
	
	public func bio(session: Session) async -> ArtistBio? {
		await session.artistBio(artistId: id)
	}
	
	public func isInFavorites(session: Session) async -> Bool? {
		await session.favorites?.doFavoritesContainArtist(artistId: id)
	}
	
	public func pictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.imageUrl(imageId: picture, resolution: resolution)
	}
	
	public func radio(session: Session) async -> [Track]? {
		await session.artistRadio(artistId: id)
	}
	
	public static func == (lhs: Artist, rhs: Artist) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

public struct ArtistBio: Decodable {
	public let source: String
	public let lastUpdated: Date
	public let text: String
	
	public var lastUpdatedString: String {
		DateFormatter.dateOnly.string(from: lastUpdated)
	}
}

// MARK: - Artist & Contributor String

extension Array where Element == Artist {
	public func formArtistString() -> String {
		let artistsAsContributors = self.map { Contributor(id: $0.id, name: $0.name) }
		
		return artistsAsContributors.formContributorString()
	}
}

extension Array where Element == Contributor {
	public func formContributorString() -> String {
		var contributorString: String = ""
		let contributors = self
		
		guard !contributors.isEmpty else {
			return contributorString
		}
		
		// First
		contributorString += contributors[0].name
		
		guard contributors.count > 1 else {
			return contributorString
		}
		
		// Middles
		if contributors.count > 2 {
			for i in 1 ..< contributors.count - 1 {
				contributorString += ", \(contributors[i].name)"
			}
		}
		
		// Last
		contributorString += " & \(contributors.last!.name)"
		
		return contributorString
	}
}

public enum ArtistSorting: Int, Codable {
	case dateAdded // to Favorites
	case name
	case popularity
}

extension Array where Element == Artist {
	public func sortedArtists(by sorting: ArtistSorting) -> [Artist] {
		switch sorting {
		case .dateAdded:
			return self
		case .name:
			return self.sorted { $0.name.lowercased() < $1.name.lowercased() }
		case .popularity:
			return self.sorted {
				($0.popularity ?? 0, $0.name.lowercased()) <
					($1.popularity ?? 0, $1.name.lowercased())
			}
		}
	}
}
