//
//  HLSPlaylist.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

/// The parts of an HLS playlist needed to download a video
nonisolated enum HLSPlaylist {
	enum ParseError: Error {
		/// The stream uses features the downloader doesn't handle, like encryption or byte ranges
		case unsupportedStream
	}
	
	/// A multivariant playlist, listing the video's qualities
	struct Master {
		let variants: [Variant]
		
		init(_ text: String, baseURL: URL) throws {
			var variants: [Variant] = []
			var pendingVariant: [String: String]?
			for line in text.playlistLines {
				if let attributes = line.attributes(of: "#EXT-X-STREAM-INF:") {
					pendingVariant = attributes
				} else if !line.hasPrefix("#"), let attributes = pendingVariant {
					pendingVariant = nil
					if let variant = Variant(attributes, uri: line, baseURL: baseURL) {
						variants.append(variant)
					}
				}
			}
			guard !variants.isEmpty else { throw ParseError.unsupportedStream }
			self.variants = variants
		}
		
		/// The variant with the highest resolution, and the highest bandwidth among those
		var best: Variant {
			variants.max { ($0.height, $0.bandwidth) < ($1.height, $1.bandwidth) }!
		}
	}
	
	struct Variant {
		let url: URL
		let bandwidth: Int
		let height: Int
		
		init?(_ attributes: [String: String], uri: String, baseURL: URL) {
			guard let url = URL(string: uri, relativeTo: baseURL)?.absoluteURL,
				  let bandwidth = attributes["BANDWIDTH"].flatMap(Int.init) else { return nil }
			self.url = url
			self.bandwidth = bandwidth
			self.height = attributes["RESOLUTION"]?.split(separator: "x").last.flatMap { Int($0) } ?? 0
		}
	}
	
	/// A media playlist, listing the segments of a single variant
	struct Media {
		/// The fragmented MP4 header that precedes the segments. Transport stream segments don't have one.
		let initializationSegment: URL?
		let segments: [URL]
		
		/// The initialization segment, followed by the media segments
		var allSegments: [URL] {
			[initializationSegment].compactMap { $0 } + segments
		}
		
		init(_ text: String, baseURL: URL) throws {
			var initializationSegment: URL?
			var segments: [URL] = []
			for line in text.playlistLines {
				if let attributes = line.attributes(of: "#EXT-X-MAP:") {
					guard attributes["BYTERANGE"] == nil, let uri = attributes["URI"] else { throw ParseError.unsupportedStream }
					initializationSegment = URL(string: uri, relativeTo: baseURL)?.absoluteURL
				} else if let attributes = line.attributes(of: "#EXT-X-KEY:") {
					guard attributes["METHOD"] == "NONE" else { throw ParseError.unsupportedStream }
				} else if line.hasPrefix("#EXT-X-BYTERANGE") {
					throw ParseError.unsupportedStream
				} else if !line.hasPrefix("#") {
					guard let url = URL(string: line, relativeTo: baseURL)?.absoluteURL else { throw ParseError.unsupportedStream }
					segments.append(url)
				}
			}
			guard !segments.isEmpty else { throw ParseError.unsupportedStream }
			self.initializationSegment = initializationSegment
			self.segments = segments
		}
	}
}

private nonisolated extension String {
	var playlistLines: [String] {
		split(whereSeparator: \.isNewline)
			.map { $0.trimmingCharacters(in: .whitespaces) }
			.filter { !$0.isEmpty }
	}
	
	/// The attribute list of a tag, like `#EXT-X-STREAM-INF:BANDWIDTH=441999,RESOLUTION=320x180`, without the quotes around values
	func attributes(of tag: String) -> [String: String]? {
		guard hasPrefix(tag) else { return nil }
		var attributes: [String: String] = [:]
		var rest = dropFirst(tag.count)[...]
		while !rest.isEmpty {
			guard let equals = rest.firstIndex(of: "=") else { break }
			let key = rest[..<equals].trimmingCharacters(in: .whitespaces)
			rest = rest[rest.index(after: equals)...]
			let value: Substring
			if rest.first == "\"" {
				// Quoted values may contain commas
				let afterQuote = rest.dropFirst()
				let closing = afterQuote.firstIndex(of: "\"") ?? afterQuote.endIndex
				value = afterQuote[..<closing]
				rest = afterQuote[closing...].drop { $0 != "," }
			} else {
				let comma = rest.firstIndex(of: ",") ?? rest.endIndex
				value = rest[..<comma]
				rest = rest[comma...]
			}
			rest = rest.drop { $0 == "," }
			attributes[key] = String(value)
		}
		return attributes
	}
}
