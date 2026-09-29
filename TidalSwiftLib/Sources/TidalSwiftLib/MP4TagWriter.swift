//
//  MP4TagWriter.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import AVFoundation

/// Writes tags as iTunes metadata via a passthrough export, so the audio isn't re-encoded.
///
/// The file is rewritten, as AVFoundation can't edit metadata in place.
nonisolated enum MP4TagWriter {
	private enum WriteError: Error {
		case exportUnavailable
		case exportFailed(Error?)
	}

	@concurrent
	static func write(_ tags: AudioTags, to url: URL) async throws {
		let asset = AVURLAsset(url: url)
		guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
			throw WriteError.exportUnavailable
		}
		exportSession.metadata = metadataItems(for: tags)
		let fileType: AVFileType = url.pathExtension.lowercased() == "m4a" ? .m4a : .mp4

		let temporaryDirectory = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
		defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
		let temporaryUrl = temporaryDirectory.appendingPathComponent(url.lastPathComponent)

		if #available(macOS 15, iOS 18, *) {
			try await exportSession.export(to: temporaryUrl, as: fileType)
		} else {
			exportSession.outputURL = temporaryUrl
			exportSession.outputFileType = fileType
			await exportSession.export()
			guard exportSession.status == .completed else {
				throw WriteError.exportFailed(exportSession.error)
			}
		}

		_ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryUrl)
	}

	private static func metadataItems(for tags: AudioTags) -> [AVMetadataItem] {
		var items = [
			item(.iTunesMetadataSongName, tags.title),
			item(.iTunesMetadataArtist, tags.artist),
			item(.iTunesMetadataAlbum, tags.album),
			item(.iTunesMetadataAlbumArtist, tags.albumArtist),
			item(.iTunesMetadataReleaseDate, tags.releaseDate),
			item(.iTunesMetadataCopyright, tags.copyright),
		].compactMap { $0 }
		items.append(item(.iTunesMetadataTrackNumber, numberPair(tags.trackNumber, of: tags.trackTotal, trailingPadding: true), dataType: kCMMetadataBaseDataType_RawData))
		items.append(item(.iTunesMetadataDiscNumber, numberPair(tags.discNumber, of: tags.discTotal, trailingPadding: false), dataType: kCMMetadataBaseDataType_RawData))
		if tags.isCompilation {
			items.append(item(.iTunesMetadataDiscCompilation, NSNumber(value: 1), dataType: kCMMetadataBaseDataType_SInt8))
		}
		if tags.isExplicit {
			items.append(item(.iTunesMetadataContentRating, NSNumber(value: 1), dataType: kCMMetadataBaseDataType_SInt8))
		}
		if let cover = tags.cover {
			items.append(item(.iTunesMetadataCoverArt, cover as NSData, dataType: kCMMetadataBaseDataType_JPEG))
		}
		return items
	}
	
	private static func item(_ identifier: AVMetadataIdentifier, _ string: String?) -> AVMetadataItem? {
		guard let string, !string.isEmpty else {
			return nil
		}
		return item(identifier, string as NSString, dataType: kCMMetadataBaseDataType_UTF8)
	}
	
	private static func item(_ identifier: AVMetadataIdentifier, _ value: NSCopying & NSObjectProtocol, dataType: CFString) -> AVMetadataItem {
		let item = AVMutableMetadataItem()
		item.identifier = identifier
		item.value = value
		item.dataType = dataType as String
		return item
	}
	
	/// `trkn` has two trailing padding bytes, `disk` doesn't
	private static func numberPair(_ number: Int, of total: Int?, trailingPadding: Bool) -> NSData {
		var data = Data(count: 2)
		for value in [number, total ?? 0] {
			let clamped = UInt16(clamping: value)
			data.append(UInt8(clamped >> 8))
			data.append(UInt8(clamped & 0xFF))
		}
		if trailingPadding {
			data.append(Data(count: 2))
		}
		return data as NSData
	}
}
