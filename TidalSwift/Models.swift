//
//  Models.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

class Model {
	var id: Int
	var name: String
	
	init(id: Int, name: String) {
		self.id = id
		self.name = name
	}
}

class Artist: Model {
	lazy var image: Data = {
		return Data()
	}()
}

class Album: Model {
	var artist: Artist
	var numTracks: Int
	var duration: Int
	var releaseDate: Date
	
	lazy var image: Data = {
		return Data()
	}()
	
	init(id: Int, name: String, artist: Artist,
		 numTracks: Int, duration: Int, releaseDate: Date) {
		self.artist = artist
		self.numTracks = numTracks
		self.duration = duration
		self.releaseDate = releaseDate
		
		super.init(id: id, name: name)
	}
}

class Playlist: Model {
	var description: String
	var creator: String // Maybe User instead of String
	var type: String // No idea yet what it's for
	var isPublic: Bool
	var created: Date
	var lastUpdated: Date
	var numTracks: Int
	var duration: Int
	
	lazy var image: Data = {
		return Data()
	}()
	
	init(id: Int, name: String, description: String, creator: String,
		 type: String, isPublic: Bool, created: Date, lastUpdated: Date,
		 numTracks: Int, duration: Int) {
		self.description = description
		self.creator = creator
		self.type = type
		self.isPublic = isPublic
		self.created = created
		self.lastUpdated = lastUpdated
		self.numTracks = numTracks
		self.duration = duration
		
		super.init(id: id, name: name)
	}
}

class Track: Model {
	var duration: Int
	var trackNum: Int
	var discNum: Int
	var popularity: Int
	var artist: Artist
	var album: Album
	var available: Bool
	
	init(id: Int, name: String, duration: Int, trackNum: Int, discNum: Int,
		 popularity: Int, artist: Artist, album: Album, available: Bool) {
		self.duration = duration
		self.trackNum = trackNum
		self.discNum = discNum
		self.popularity = popularity
		self.artist = artist
		self.album = album
		self.available = available
		
		super.init(id: id, name: name)
	}
}

class SearchResult {
	var artists = [Artist]()
	var albums = [Album]()
	var tracks = [Track]()
	var playlists = [Playlist]()
	var topHit: Track?
}

class Category: Model {
	lazy var image: Data = {
		return Data()
	}()
}
