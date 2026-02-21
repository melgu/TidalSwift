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
	
	public func newReleasesFromFavoriteArtists(number: Int = 30, includeEps: Bool) async -> [Album]? {
		guard let favoriteArtists = await session.favorites?.artists() else {
			return nil
		}
		
		let albums = await withTaskGroup(of: [Album]?.self, returning: [Album].self) { [session] group in
			for artist in favoriteArtists {
				group.addTask { await session.artistAlbums(artistId: artist.item.id, filter: nil, limit: number) }
				if includeEps {
					group.addTask { await session.artistAlbums(artistId: artist.item.id, filter: .epsAndSingles, limit: number) }
				}
			}
			
			var allReleases = Set<Album>()
			for await albums in group {
				guard let albums else { continue }
				allReleases.formUnion(albums)
			}
			
			return Array(allReleases).sorted { $0.releaseDate ?? Date.distantPast > $1.releaseDate ?? Date.distantPast }
		}
		
		return Array(albums.prefix(number))
	}
}
