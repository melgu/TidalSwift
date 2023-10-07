//
//  Mix.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

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

public enum MixType: String, Codable {
	case header = "MIX_HEADER" // Because  of how Tidal structures its data
	case audio = "DAILY_MIX"
	case video = "VIDEO_DAILY_MIX"
	case discovery = "DISCOVERY_MIX"
}

public struct MixesItem: Codable, Equatable, Identifiable {
	public let id: String
	public let title: String
	public let subTitle: String
	public let graphic: MixesGraphic
	public let mixType: MixType
	
	public static func == (lhs: MixesItem, rhs: MixesItem) -> Bool {
		lhs.id == rhs.id
	}
}

public enum MixesGraphicType: String, Codable {
	case squaresGrid = "SQUARES_GRID"
	case rectanglesGrid = "RECTANGLES_GRID"
}

public struct MixesGraphic: Codable {
	public let type: MixesGraphicType
	public let text: String
	public let images: [MixesGraphicImage]
}

public enum MixesGraphicImageType: String, Codable {
	case artist = "ARTIST"
}

public struct MixesGraphicImage: Codable {
	public let id: String
	public let vibrantColor: String
	public let type: MixesGraphicImageType
	
	public func getImageUrl(session: Session, resolution: Int) -> URL? {
		session.imageUrl(imageId: id, resolution: resolution)
	}
	
	public func getImage(session: Session, resolution: Int) -> NSImage? {
		session.image(imageId: id, resolution: resolution)
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

enum MixPlaylistType: String, Decodable {
	case header = "MIX_HEADER" // Because  of how Tidal structures its data
	case audio = "TRACK_LIST"
	case video = "VIDEO_LIST"
}

struct MixModule: Decodable {
	let id: String
	let title: String
	let type: MixPlaylistType
	let pagedList: Tracks?
}
