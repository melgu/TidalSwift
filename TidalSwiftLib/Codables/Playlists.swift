//
//  Playlist.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

struct Playlists: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Playlist]
}

public enum PlaylistType: String, Codable {
	case user = "USER"
	case editorial = "EDITORIAL"
	case artist = "ARTIST"
	case podcast = "PODCAST"
	// Haven't seen others yet
}

public struct Playlist: Codable, Equatable, Identifiable, Hashable {
	public var id: String { uuid }
	
	public let uuid: String
	public let title: String
	public let numberOfTracks: Int
	public let numberOfVideos: Int
	public let creator: PlaylistCreator
	public let description: String?
	public let duration: Int
	public let lastUpdated: Date
	public let created: Date
	public let type: PlaylistType
	public let publicPlaylist: Bool
	public let url: URL
	public let image: String?
	public let popularity: Int
	public let squareImage: String?
	
	public func isInFavorites(session: Session) -> Bool? {
		session.favorites?.doFavoritesContainPlaylist(playlistId: uuid)
	}
	
	public func getImageUrl(session: Session, resolution: Int, resolutionY: Int? = nil) -> URL? {
		if squareImage == nil && image == nil {
			return nil
		}
		
		if let resolutionY = resolutionY {
			return session.getImageUrl(imageId: squareImage ?? image!, resolution: resolution, resolutionY: resolutionY)
		}
		
		if let squareImage = squareImage {
			return session.getImageUrl(imageId: squareImage, resolution: resolution)
		} else {
			return session.getImageUrl(imageId: image!, resolution: 480, resolutionY: 320)
		}
	}
	
	public func getImage(session: Session, resolution: Int, resolutionY: Int? = nil) -> NSImage? {
		if squareImage == nil && image == nil {
			return nil
		}
		
		if let resolutionY = resolutionY {
			return session.getImage(imageId: squareImage ?? image!, resolution: resolution, resolutionY: resolutionY)
		}
		
		if let squareImage = squareImage {
			return session.getImage(imageId: squareImage, resolution: resolution)
		} else {
			return session.getImage(imageId: image!, resolution: 480, resolutionY: 320)
		}
	}
	
	// Offline
	
	public func isOffline(session: Session) -> Bool {
		session.helpers.offline.isPlaylistOffline(playlist: self)
	}
	
	public func addOffline(session: Session) {
		session.helpers.offline.add(playlist: self)
	}
	
	public func removeOffline(session: Session) {
		session.helpers.offline.remove(playlist: self)
	}
	
	// Playlist Editing
	
	public func addTracks(_ tracks: [Track], duplicate: Bool, session: Session) -> Bool {
		return session.playlistEditing.addTracks(tracks.map(\.id), to: uuid, duplicate: duplicate)
	}
	
	public func addTrack(_ track: Track, duplicate: Bool, session: Session) -> Bool {
		return session.playlistEditing.addTrack(track.id, to: uuid, duplicate: duplicate)
	}
	
	public func removeTrack(atIndex index: Int, session: Session) -> Bool {
		return session.playlistEditing.removeTrack(atIndex: index, from: uuid)
	}
	
	public func moveTrack(fromIndex: Int, toIndex: Int, session: Session) -> Bool {
		return session.playlistEditing.moveTrack(fromIndex: fromIndex, toIndex: toIndex, in: uuid)
	}
	
	public func edit(title: String, description: String, session: Session) -> Bool {
		return session.playlistEditing.editPlaylist(playlistId: uuid, title: title, description: description)
	}
	
	public func delete(session: Session) -> Bool {
		return session.playlistEditing.deletePlaylist(playlistId: uuid)
	}
	
	public static func == (lhs: Playlist, rhs: Playlist) -> Bool {
		lhs.uuid == rhs.uuid
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
	}
}

public struct PlaylistCreator: Codable {
	public let id: Int?
	public let name: String?
	public let url: URL?
	public let picture: String?
	public let popularity: Int?
	
	public func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else {
			return nil
		}
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	public func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else {
			return nil
		}
		return session.getImage(imageId: picture, resolution: resolution)
	}
}

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
