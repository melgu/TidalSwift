//
//  FavoritesConverters.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 22.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Array where Element == FavoriteArtist {
	public func unwrapped() -> [Artist] {
		self.map { $0.item }
	}
}

extension Array where Element == FavoriteAlbum {
	public func unwrapped() -> [Album] {
		self.map { $0.item }
	}
}

extension Array where Element == FavoritePlaylist {
	public func unwrapped() -> [Playlist] {
		let tempPlaylists = self.map { $0.playlist }
		
		// Playlists can appear as userCreated and userFavorited. Only keep one.
		var resultArray: [Playlist] = []
		for playlist in tempPlaylists {
			if !resultArray.contains(playlist) {
				resultArray.append(playlist)
			}
		}
		return resultArray
	}
}

extension Array where Element == FavoriteTrack {
	public func unwrapped() -> [Track] {
		self.map { $0.item }
	}
}

extension Array where Element == FavoriteVideo {
	public func unwrapped() -> [Video] {
		self.map { $0.item }
	}
}
