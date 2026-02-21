//
//  Favorites.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

struct FavoritesResponse: Decodable {
	let updatedFavoriteArtists: Date?
	let updatedFavoriteTracks: Date?
	let updatedFavoritePlaylists: Date?
	let updatedFavoriteAlbums: Date?
	let updatedPlaylists: Date?
	let updatedVideoPlaylists: Date?
	let updatedFavoriteVideos: Date?
}

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
		lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteArtist, rhs: Artist) -> Bool {
		lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Artist, rhs: FavoriteArtist) -> Bool {
		lhs.id == rhs.item.id
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
		lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteAlbum, rhs: Album) -> Bool {
		lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Album, rhs: FavoriteAlbum) -> Bool {
		lhs.id == rhs.item.id
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
		lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteTrack, rhs: Track) -> Bool {
		lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Track, rhs: FavoriteTrack) -> Bool {
		lhs.id == rhs.item.id
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
		lhs.item.id == rhs.item.id
	}
	
	public static func == (lhs: FavoriteVideo, rhs: Video) -> Bool {
		lhs.item.id == rhs.id
	}
	
	public static func == (lhs: Video, rhs: FavoriteVideo) -> Bool {
		lhs.id == rhs.item.id
	}
}

struct FavoritePlaylists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [FavoritePlaylist]
}

public enum FavoritePlaylistType: String, Decodable {
	case userCreated = "USER_CREATED"
	case userFavorited = "USER_FAVORITE"
}

public struct FavoritePlaylist: Decodable, Equatable {
	public var id: String { playlist.id }
	
	public let type: FavoritePlaylistType
	public let created: Date
	public let playlist: Playlist
	
	public static func == (lhs: FavoritePlaylist, rhs: FavoritePlaylist) -> Bool {
		lhs.playlist.uuid == rhs.playlist.uuid
	}
	
	public static func == (lhs: FavoritePlaylist, rhs: Playlist) -> Bool {
		lhs.playlist.uuid == rhs.uuid
	}
	
	public static func == (lhs: Playlist, rhs: FavoritePlaylist) -> Bool {
		lhs.uuid == rhs.playlist.uuid
	}
}
