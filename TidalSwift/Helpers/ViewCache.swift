//
//  ViewCache.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 26.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct ViewCache: Codable {
	var searchResponses: [String: SearchResponse] = [:]
	
	var newReleases: [Album]?
	var mixes: [MixesItem]?
	
	var favoriteArtists: [Artist]?
	var favoriteAlbums: [Album]?
	var favoritePlaylists: [Playlist]?
	var favoriteTracks: [Track]?
	var favoriteVideos: [Video]?
	
//	var artist: [Int: Artist] = [:]
//	var album: [Int: Album] = [:]
//	var playlist: [String: Playlist] = [:]
//	var video: [Int: Video] = [:]
	
	var mixTracks: [String: [Track]] = [:]
	var artistTopTracks: [Int: [Track]] = [:]
	var artistAlbums: [Int: [Album]] = [:]
	var artistAlbumsEpsAndSingles: [Int: [Album]] = [:]
	var artistAlbumsAppearances: [Int: [Album]] = [:]
	var artistVideos: [Int: [Video]] = [:]
	var albumTracks: [Int: [Track]] = [:]
	var playlistTracks: [String: [Track]] = [:]
}
