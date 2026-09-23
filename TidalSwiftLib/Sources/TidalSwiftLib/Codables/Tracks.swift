//
//  Track.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

struct Tracks: Decodable {
	let limit: Int
	let offset: Int
	let totalNumberOfItems: Int
	let items: [Track]
}

public struct TrackMixes: Codable {
	public let trackMix: String?
	
	enum CodingKeys: String, CodingKey {
		case trackMix = "TRACK_MIX"
	}
}

public struct Track: Codable, Equatable, Identifiable, Hashable {
	public let id: Int
	public let title: String
	public let duration: Int
	public let replayGain: Float
	public let peak: Float?
	public let allowStreaming: Bool
	public let streamReady: Bool
	public let streamStartDate: Date?
	public let premiumStreamingOnly: Bool?
	public let trackNumber: Int
	public let volumeNumber: Int
	public let version: String?
	public let popularity: Int
	public let copyright: String?
	public let description: String?
	public let url: URL
	public let isrc: String?
	public let editable: Bool
	public let explicit: Bool
	public let audioQuality: AudioQuality?
	public let audioModes: [AudioMode]?
	public let artist: Artist?
	public let artists: [Artist]
	public let album: Album
	public let mixes: TrackMixes?
	public let dateAdded: Date?
	public let index: Int?
	public let itemUuid: UUID?
	
	public func isInFavorites(session: Session) async -> Bool? {
		await session.favorites?.doFavoritesContainTrack(trackId: id)
	}
	
	public func getCoverUrl(session: Session, resolution: Int) -> URL? {
		album.getCoverUrl(session: session, resolution: resolution)
	}
	
	public func getCredits(session: Session) async -> [Credit]? {
		await session.trackCredits(trackId: id)
	}
	
	public func getLyrics(session: Session) async -> Lyrics? {
		await session.lyrics(trackId: id)
	}
	
	public var hasDolbyAtmos: Bool {
		audioModes?.contains(.dolbyAtmos) ?? false
	}
	
	public var hasStereo: Bool {
		guard let audioModes else { return true }
		return audioModes.contains(.stereo) || audioModes.contains(.mono)
	}
	
	/// Dolby Atmos is used when preferred or when the track has no stereo version
	public func audioStream(session: Session, audioQuality: AudioQuality, preferDolbyAtmos: Bool) async -> AudioStream? {
		if hasDolbyAtmos && (preferDolbyAtmos || !hasStereo) {
			if let url = await session.dolbyAtmosUrl(trackId: id) {
				return AudioStream(url: url, pathExtension: "m4a", isDolbyAtmos: true)
			}
			if !hasStereo {
				return nil
			}
		}
		guard let url = await session.audioUrl(trackId: id, audioQuality: audioQuality) else {
			return nil
		}
		return AudioStream(url: url, pathExtension: session.pathExtension(for: audioQuality), isDolbyAtmos: false)
	}
	
	public func isOffline(session: Session) async -> Bool {
		await session.helpers.offline.isTrackOffline(track: self)
	}
	
	public func radio(session: Session) async -> [Track]? {
		await session.trackRadio(trackId: id)
	}
	
	public static func == (lhs: Track, rhs: Track) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

public struct AudioStream {
	public let url: URL
	public let pathExtension: String
	public let isDolbyAtmos: Bool
}

struct TrackPlaybackInfo: Decodable {
	let audioMode: AudioMode
	let manifestMimeType: String
	let manifest: String
}

struct TrackManifest: Decodable {
	let codecs: String
	let encryptionType: String
	let urls: [URL]
}

struct AudioUrl: Decodable {
	let url: URL
	let trackId: Int
	let soundQuality: AudioQuality
	let encryptionKey: String
	let codec: String
}

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
