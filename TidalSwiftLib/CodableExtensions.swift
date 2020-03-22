//
//  CodableExtensions.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

// MARK: Sorting
/// Secondary sorting is always by title

extension Array {
	// Only reversed if b is true
	public func reversed(_ b: Bool) -> [Element] {
		b ? self.reversed() : self
	}
}

// MARK: - Artist

public enum ArtistSorting: Int, Codable {
	case dateAdded // to Favorites
	case name
	case popularity
}

extension Array where Element == Artist {
	public func sortedArtists(by sorting: ArtistSorting) -> [Artist] {
		switch sorting {
		case .dateAdded:
			return self
		case .name:
			return self.sorted { $0.name.lowercased() < $1.name.lowercased() }
		case .popularity:
			return self.sorted {
				($0.popularity ?? 0, $0.name.lowercased()) <
					($1.popularity ?? 0, $1.name.lowercased())
			}
		}
	}
}

// MARK: - Album

public enum AlbumSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case artists // Optional
	case releaseDate // Optional
	case duration // Optional
	case popularity // Optional
}

extension Array where Element == Album {
	public func sortedAlbums(by sorting: AlbumSorting) -> [Album] {
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .artists:
			return self.sorted {
				($0.artists?.formArtistString().lowercased() ?? "zzzzzzzzzz", $0.title.lowercased()) <
					($1.artists?.formArtistString().lowercased() ?? "zzzzzzzzzz", $1.title.lowercased())
			}
		case .releaseDate:
			return self.sorted {
				($0.releaseDate ?? Date.distantPast, $0.title.lowercased()) <
					($1.releaseDate ?? Date.distantPast, $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration ?? 0, $0.title.lowercased()) <
					($1.duration ?? 0, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity ?? 0, $0.title.lowercased()) <
					($1.popularity ?? 0, $1.title.lowercased())
			}
		}
	}
}

// MARK: - Playlist

public enum PlaylistSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case lastUpdated
	case created
	case numberOfTracks
	case duration
	case type
	case popularity  // Optional
	case creator
}

extension Array where Element == Playlist {
	public func sortedPlaylists(by sorting: PlaylistSorting) -> [Playlist] {
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .lastUpdated:
			return self.sorted {
				($0.lastUpdated, $0.title.lowercased()) <
					($1.lastUpdated, $1.title.lowercased())
			}
		case .created:
			return self.sorted {
				($0.created, $0.title.lowercased()) <
					($1.created, $1.title.lowercased())
			}
		case .numberOfTracks:
			return self.sorted {
				($0.numberOfTracks, $0.title.lowercased()) <
					($1.numberOfTracks, $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration, $0.title.lowercased()) <
					($1.duration, $1.title.lowercased())
			}
		case .type:
			return self.sorted {
				($0.type.rawValue, $0.title.lowercased()) <
					($1.type.rawValue, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity, $0.title.lowercased()) <
					($1.popularity, $1.title.lowercased())
			}
		case .creator:
			return self.sorted {
				($0.creator.name ?? "zzzzzzzzzz", $0.title.lowercased()) <
					($1.creator.name ?? "zzzzzzzzzz", $1.title.lowercased())
			}
		}
	}
}

// MARK: - Track

public enum TrackSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case artists
	case album
	case duration
	case popularity
	case albumReleaseDate
}

extension Array where Element == Track {
	public func sortedTracks(by sorting: TrackSorting) -> [Track] {
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .artists:
			return self.sorted {
				($0.artists.formArtistString().lowercased(), $0.title.lowercased()) <
					($1.artists.formArtistString().lowercased(), $1.title.lowercased())
			}
		case .album:
			return self.sorted {
				($0.album.title.lowercased(), $0.title.lowercased()) <
					($1.album.title.lowercased(), $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration, $0.title.lowercased()) <
					($1.duration, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity, $0.title.lowercased()) <
					($1.popularity, $1.title.lowercased())
			}
		case .albumReleaseDate:
			return self.sorted {
				($0.album.releaseDate ?? Date.distantPast, $0.title.lowercased()) <
					($1.album.releaseDate ?? Date.distantPast, $1.title.lowercased())
			}
		}
	}
}

// MARK: - Video

public enum VideoSorting: Int, Codable {
	case dateAdded // to Favorites
	case title
	case artists
	case releaseDate
	case duration
	case popularity
}

extension Array where Element == Video {
	public func sortedVideos(by sorting: VideoSorting) -> [Video] {
		switch sorting {
		case .dateAdded:
			return self
		case .title:
			return self.sorted { $0.title.lowercased() < $1.title.lowercased() }
		case .artists:
			return self.sorted {
				($0.artists.formArtistString().lowercased(), $0.title.lowercased()) <
					($1.artists.formArtistString().lowercased(), $1.title.lowercased())
			}
		case .releaseDate:
			return self.sorted {
				($0.releaseDate, $0.title.lowercased()) <
					($1.releaseDate, $1.title.lowercased())
			}
		case .duration:
			return self.sorted {
				($0.duration, $0.title.lowercased()) <
					($1.duration, $1.title.lowercased())
			}
		case .popularity:
			return self.sorted {
				($0.popularity, $0.title.lowercased()) <
					($1.popularity, $1.title.lowercased())
			}
		}
	}
}
