//
//  Lyrics.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 09.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

public struct Lyrics: Codable, Equatable {
	public let trackId: Int
	public let lyricsProvider: String?
	public let providerCommontrackId: String?
	public let providerLyricsId: String?
	public let lyrics: String
	public let subtitles: String? // Same lyrics, but with LRC timestamps
	public let isRightToLeft: Bool?
}
