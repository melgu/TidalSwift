//
//  Releases.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

/// Tidal's categories of an artist's releases
enum ReleaseType: String, CaseIterable, Codable {
	case albums
	case epsAndSingles = "eps-and-singles"
	/// Compilations and other artists' albums the artist appears on
	case appearances
	
	var filter: Session.ArtistAlbumFilter? {
		switch self {
		case .albums: nil
		case .epsAndSingles: .epsAndSingles
		case .appearances: .appearances
		}
	}
}

struct ArtistReleases: Codable {
	let artist: ArtistSummary
	let type: ReleaseType
	/// Newest first
	let releases: [AlbumSummary]
}

/// An artist's releases of one type, newest first
@MainActor
func artistReleases(session: Session, reference: String, type: ReleaseType, limit: Int?) async throws -> ArtistReleases {
	guard case .artist(let id) = try TidalLink(reference: reference, kind: .artist) else {
		throw CLIError("\(reference) isn't an artist")
	}
	guard let artist = await session.artist(artistId: id) else {
		throw CLIError("Couldn't load artist \(id)")
	}
	guard let albums = await session.artistAlbums(artistId: id, filter: type.filter) else {
		throw CLIError("Couldn't load the releases of \(artist.name)")
	}
	// Sorted here, as Tidal's order isn't reliably by date
	let sorted = albums.sorted { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
	return ArtistReleases(
		artist: ArtistSummary(artist),
		type: type,
		releases: sorted.prefix(limit ?? .max).map(AlbumSummary.init)
	)
}

/// The newest releases of the favorite artists, as the app's New Releases shows them
@MainActor
func newReleases(session: Session, includeEpsAndSingles: Bool, limit: Int) async throws -> [AlbumSummary] {
	guard let albums = await session.helpers.newReleasesFromFavoriteArtists(number: limit, includeEps: includeEpsAndSingles) else {
		throw CLIError("Couldn't load the favorite artists")
	}
	return albums.map(AlbumSummary.init)
}
