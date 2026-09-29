//
//  FLACTagWriter.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Writes tags as a Vorbis comment and the cover as a picture block.
///
/// Format: `fLaC` marker, metadata blocks, audio frames (https://www.rfc-editor.org/rfc/rfc9639).
/// Existing tag, picture and padding blocks are replaced, all others (e.g. stream info and seek table) are kept.
/// The file is rewritten, as there is no room to insert blocks in place.
nonisolated enum FLACTagWriter {
	private enum WriteError: Error {
		case notFLAC
		case truncated
		case blockTooLarge
	}

	private enum BlockType: UInt8 {
		case padding = 1
		case vorbisComment = 4
		case picture = 6
	}

	private struct Block {
		var type: UInt8
		var body: Data
	}

	private static let marker = Data("fLaC".utf8)
	private static let maxBlockLength = (1 << 24) - 1
	/// Allows later tag edits in place
	private static let paddingLength = 8192
	private static let copyChunkLength = 1 << 20

	@concurrent
	static func write(_ tags: AudioTags, to url: URL) async throws {
		let input = try FileHandle(forReadingFrom: url)
		defer { try? input.close() }

		var blocks = try readBlocks(from: input).filter {
			![BlockType.padding, .vorbisComment, .picture].map(\.rawValue).contains($0.type)
		}
		blocks.append(Block(type: BlockType.vorbisComment.rawValue, body: vorbisComment(for: tags)))
		if let cover = tags.cover, let picture = pictureBody(for: cover), picture.count <= maxBlockLength {
			blocks.append(Block(type: BlockType.picture.rawValue, body: picture))
		}
		blocks.append(Block(type: BlockType.padding.rawValue, body: Data(count: paddingLength)))

		var header = marker
		for (index, block) in blocks.enumerated() {
			guard block.body.count <= maxBlockLength else {
				throw WriteError.blockTooLarge
			}
			let isLast = index == blocks.count - 1
			header.append((isLast ? 0x80 : 0) | block.type)
			header.append(bigEndian: UInt32(block.body.count), byteCount: 3)
			header.append(block.body)
		}

		let temporaryDirectory = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
		defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
		let temporaryUrl = temporaryDirectory.appendingPathComponent(url.lastPathComponent)

		FileManager.default.createFile(atPath: temporaryUrl.path, contents: header)
		let output = try FileHandle(forWritingTo: temporaryUrl)
		defer { try? output.close() }
		try output.seekToEnd()

		// Input is positioned at the first audio frame after reading the blocks
		while let chunk = try input.read(upToCount: copyChunkLength), !chunk.isEmpty {
			try output.write(contentsOf: chunk)
		}
		try output.close()

		_ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryUrl)
	}

	private static func readBlocks(from input: FileHandle) throws -> [Block] {
		guard try input.read(upToCount: marker.count) == marker else {
			throw WriteError.notFLAC
		}

		var blocks = [Block]()
		var isLast = false
		while !isLast {
			guard let blockHeader = try input.read(upToCount: 4), blockHeader.count == 4 else {
				throw WriteError.truncated
			}
			isLast = blockHeader[0] & 0x80 != 0
			let length = blockHeader[1...3].reduce(0) { $0 << 8 | Int($1) }
			let body = try input.read(upToCount: length) ?? Data()
			guard body.count == length else {
				throw WriteError.truncated
			}
			blocks.append(Block(type: blockHeader[0] & 0x7F, body: body))
		}
		return blocks
	}

	/// Little-endian, unlike the rest of FLAC (https://www.xiph.org/vorbis/doc/v-comment.html)
	private static func vorbisComment(for tags: AudioTags) -> Data {
		var fields: [(String, String?)] = [
			("TITLE", tags.title),
			("ARTIST", tags.artist),
			("ALBUM", tags.album),
			("ALBUMARTIST", tags.albumArtist),
			("TRACKNUMBER", String(tags.trackNumber)),
			("TRACKTOTAL", tags.trackTotal.map(String.init)),
			("DISCNUMBER", String(tags.discNumber)),
			("DISCTOTAL", tags.discTotal.map(String.init)),
			("DATE", tags.releaseDate),
			("COPYRIGHT", tags.copyright),
			("ISRC", tags.isrc),
		]
		if tags.isCompilation {
			fields.append(("COMPILATION", "1"))
		}
		if tags.isExplicit {
			fields.append(("ITUNESADVISORY", "1"))
		}
		let comments = fields.compactMap { key, value in
			value.flatMap { $0.isEmpty ? nil : Data("\(key)=\($0)".utf8) }
		}

		let vendor = Data("TidalSwift".utf8)
		var body = Data()
		body.append(littleEndian: UInt32(vendor.count))
		body.append(vendor)
		body.append(littleEndian: UInt32(comments.count))
		for comment in comments {
			body.append(littleEndian: UInt32(comment.count))
			body.append(comment)
		}
		return body
	}

	private static func pictureBody(for image: Data) -> Data? {
		guard let source = CGImageSourceCreateWithData(image as CFData, nil),
			  let typeIdentifier = CGImageSourceGetType(source) as String?,
			  let mimeType = UTType(typeIdentifier)?.preferredMIMEType,
			  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
			  let width = properties[kCGImagePropertyPixelWidth] as? Int,
			  let height = properties[kCGImagePropertyPixelHeight] as? Int else {
			return nil
		}
		let bitsPerComponent = properties[kCGImagePropertyDepth] as? Int ?? 8
		let componentCount = properties[kCGImagePropertyHasAlpha] as? Bool == true ? 4 : 3

		let mime = Data(mimeType.utf8)
		var body = Data()
		body.append(bigEndian: 3, byteCount: 4) // Front cover
		body.append(bigEndian: UInt32(mime.count), byteCount: 4)
		body.append(mime)
		body.append(bigEndian: 0, byteCount: 4) // Description length
		body.append(bigEndian: UInt32(width), byteCount: 4)
		body.append(bigEndian: UInt32(height), byteCount: 4)
		body.append(bigEndian: UInt32(bitsPerComponent * componentCount), byteCount: 4)
		body.append(bigEndian: 0, byteCount: 4) // Number of colors, only for indexed images
		body.append(bigEndian: UInt32(image.count), byteCount: 4)
		body.append(image)
		return body
	}
}

private nonisolated extension Data {
	mutating func append(bigEndian value: UInt32, byteCount: Int) {
		for shift in stride(from: (byteCount - 1) * 8, through: 0, by: -8) {
			append(UInt8(truncatingIfNeeded: value >> shift))
		}
	}

	mutating func append(littleEndian value: UInt32) {
		for shift in stride(from: 0, through: 24, by: 8) {
			append(UInt8(truncatingIfNeeded: value >> shift))
		}
	}
}
