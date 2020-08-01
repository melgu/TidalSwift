//
//  Helpers.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Combine

public class Helpers {
	unowned let session: Session
	private let metadata: Metadata
	public let downloadStatus = DownloadStatus()
	public let offline: Offline
	public let download: Download
	
	public init(session: Session) {
		self.session = session
		self.metadata = Metadata(session: session)
		self.offline = Offline(session: session, downloadStatus: downloadStatus)
		self.download = Download(session: session, metadata: self.metadata, downloadStatus: downloadStatus)
	}
	
	public func newReleasesFromFavoriteArtists(number: Int = 30) -> [Album]? {
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
