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
	
	// Parses the LRC subtitles, e.g. "[01:23.45] Some line". Nil if there are none.
	public var syncedLines: [SyncedLyricsLine]? {
		guard let subtitles else {
			return nil
		}
		let lines: [SyncedLyricsLine] = subtitles.split(separator: "\n").compactMap { line in
			guard line.hasPrefix("["), let closing = line.firstIndex(of: "]") else {
				return nil
			}
			let timestamp = line[line.index(after: line.startIndex)..<closing].split(separator: ":")
			guard timestamp.count == 2, let minutes = Double(timestamp[0]), let seconds = Double(timestamp[1]) else {
				return nil
			}
			let text = line[line.index(after: closing)...].trimmingCharacters(in: .whitespaces)
			return SyncedLyricsLine(time: minutes * 60 + seconds, text: text)
		}
		return lines.isEmpty ? nil : lines.sorted { $0.time < $1.time }
	}
}

public struct SyncedLyricsLine: Equatable {
	public let time: Double
	public let text: String
}
