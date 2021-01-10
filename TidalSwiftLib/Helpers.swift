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
	
	public func newReleasesFromFavoriteArtists(number: Int = 30, includeEps: Bool) -> [Album]? {
		let optionalFavoriteArtists = session.favorites?.artists()
		guard let favoriteArtists = optionalFavoriteArtists else {
			return nil
		}
		
		var allReleases = Set<Album>() 
		for artist in favoriteArtists {
			if let albums = session.getArtistAlbums(artistId: artist.item.id,
													filter: nil,
													limit: number) {
				allReleases.formUnion(albums)
			}
			if includeEps {
				if let albums = session.getArtistAlbums(artistId: artist.item.id,
														filter: .epsAndSingles,
														limit: number) {
					allReleases.formUnion(albums)
				}
			}
		}
		
		let sortedReleases = Array(allReleases).sorted { $0.releaseDate ?? Date.distantPast > $1.releaseDate ?? Date.distantPast }
		return Array(sortedReleases.prefix(number))
	}
}
