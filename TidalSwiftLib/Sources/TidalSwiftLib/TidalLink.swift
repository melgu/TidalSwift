//
//  TidalLink.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

/// An item a Tidal web or app link points to.
public enum TidalLink: Equatable, Sendable {
	case track(id: Int)
	case album(id: Int)
	case artist(id: Int)
	case playlist(uuid: String)
	
	/// Parses links like `https://tidal.com/browse/album/123`, `https://listen.tidal.com/track/123/u`,
	/// `http://www.tidal.com/playlist/<uuid>` or `tidal://artist/123`. The scheme may be left out.
	public init?(string: String) {
		var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
		if !string.contains("://") {
			string = "https://" + string
		}
		guard let url = URL(string: string) else {
			return nil
		}
		self.init(url: url)
	}
	
	public init?(url: URL) {
		guard let scheme = url.scheme?.lowercased(), let host = url.host()?.lowercased() else {
			return nil
		}
		
		var components = url.pathComponents.filter { $0 != "/" }
		switch scheme {
		case "http", "https":
			guard host == "tidal.com" || host.hasSuffix(".tidal.com") else {
				return nil
			}
		case "tidal":
			// The host is the first path component, as in tidal://album/123
			components.insert(host, at: 0)
		default:
			return nil
		}
		
		// Take the last match, so album/123/track/456 opens the track
		var link: TidalLink?
		for (type, id) in zip(components, components.dropFirst()) {
			link = TidalLink(type: type.lowercased(), id: id) ?? link
		}
		guard let link else {
			return nil
		}
		self = link
	}
	
	private init?(type: String, id: String) {
		switch type {
		case "track":
			guard let id = Int(id) else { return nil }
			self = .track(id: id)
		case "album":
			guard let id = Int(id) else { return nil }
			self = .album(id: id)
		case "artist":
			guard let id = Int(id) else { return nil }
			self = .artist(id: id)
		case "playlist":
			guard UUID(uuidString: id) != nil else { return nil }
			self = .playlist(uuid: id.lowercased())
		default:
			return nil
		}
	}
}
