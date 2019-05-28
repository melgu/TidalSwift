//
//  Helpers.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

class Helpers {
	
	unowned let session: Session
	
	init(session: Session) {
		self.session = session
	}
	
	func newReleasesFromFavoriteArtists(number: Int = 30) -> [Album]? {
		let optionalFavoriteArtists = session.favorites?.artists()
		guard let favoriteArtists = optionalFavoriteArtists else {
			return nil
		}
		
		var allReleases = [Album]()
		for artist in favoriteArtists {
			let optionalAlbums = session.getArtistAlbums(artistId: artist.item.id, limit: number)
			guard let albums = optionalAlbums else {
				continue
			}
			allReleases += albums
		}
		
		allReleases.sort { $0.releaseDate! > $1.releaseDate! }
		return Array(allReleases.prefix(number))
	}
	
}
