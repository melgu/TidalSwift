//
//  Featured+Moods.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

public typealias Mood = Genre

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
	
	public func imageUrl(session: Session, resolution: Int) -> URL? {
		session.imageUrl(imageId: image, resolution: resolution)
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
	
	public func imageUrl(session: Session, resolution: Int, resolutionY: Int) -> URL? {
		session.imageUrl(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
	}
}
