//
//  Metadata.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 30.06.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import MP42Foundation

class Metadata {
	
	unowned let session: Session
	
	init(session: Session) {
		self.session = session
	}
	
	func setMetadata(for track: Track, at path: URL) {
		
		var m4aFile: MP42File
		do {
			m4aFile = try MP42File(url: path)
		} catch {
			displayError(title: "Error finding M4A file", content: "Path: \(path). Error: \(error)")
			return
		}
		
		var metadata = [(String, NSCopying & NSObjectProtocol, MP42MetadataItemDataType)]()
		
		metadata.append((MP42MetadataKeyName,
						 track.title as NSCopying & NSObjectProtocol,
						 .string))
		
		if !track.artists.isEmpty {
			metadata.append((MP42MetadataKeyArtist,
							 track.artists.formArtistString() as NSCopying & NSObjectProtocol,
							 .string))
		}

		metadata.append((MP42MetadataKeyAlbum,
						 track.album.title as NSCopying & NSObjectProtocol,
						 .string))
		
		if let album = session.getAlbum(albumId: track.album.id) {
			metadata.append((MP42MetadataKeyDiscNumber,
							 [track.volumeNumber, album.numberOfVolumes] as NSCopying & NSObjectProtocol,
							 .integerArray))
			
			metadata.append((MP42MetadataKeyTrackNumber,
							 [track.trackNumber, album.numberOfTracks] as NSCopying & NSObjectProtocol,
							 .integerArray))
			
			if album.artists != nil && !album.artists!.isEmpty {
				metadata.append((MP42MetadataKeyAlbumArtist,
								 album.artists!.formArtistString() as NSCopying & NSObjectProtocol,
								 .string))
			}
		}

		// TODO: Add Year as Release Date
//		if let releaseDate = track.album.releaseDate {
//			let year = ""
//			metadata.append((MP42MetadataKeyReleaseDate,
//							 year as NSCopying & NSObjectProtocol,
//							 .string))
//		}

		if let copyright = track.copyright {
			metadata.append((MP42MetadataKeyCopyright,
							 copyright as NSCopying & NSObjectProtocol,
							 .string))
		}

		if let cover = track.getCover(session: session, resolution: 1280) {
			let art = MP42Image(image: cover)
			metadata.append((MP42MetadataKeyCoverArt,
							 art,
							 .image))
		}

//		// TODO: Genre?
//		if let genre = track.primaryGenreName {
//			metadata.append((MP42MetadataKeyUserGenre,
//							 genre as NSCopying & NSObjectProtocol,
//							 MP42MetadataItemDataType.string))
//		}

		if track.explicit {
			metadata.append((MP42MetadataKeyContentRating,
							 1 as NSCopying & NSObjectProtocol,
							 .integer
							 ))
		}

		// Set compilation // TODO: Immer noch nicht korrekt
		if track.album.isCompilation {
			metadata.append((MP42MetadataKeyDiscCompilation,
							 1 as NSCopying & NSObjectProtocol,
							 .integer))
		}
		
		// iTunes Artist ID
//		metadata.append((MP42MetadataKeyArtistID,
//					 track.artistId as NSCopying & NSObjectProtocol,
//					 .integer))
		
		// Remove previous artwork
		for item in m4aFile.metadata.items where item.imageValue != nil {
			m4aFile.metadata.removeItem(item)
		}

		for metadatum in metadata {
			m4aFile.metadata.addItem(MP42MetadataItem(identifier: metadatum.0,
													  value: metadatum.1,
													  dataType: metadatum.2,
													  extendedLanguageTag: nil))
		}
		
		m4aFile.optimize()
		
		do {
			let options = [:] as [String: Any]
//				options[MP42DontUpdateBitrate] = true
			try m4aFile.update(options: options)
		} catch {
			displayError(title: "Error writing Metadata", content: "Path: \(path). Error: \(error)")
			return
		}
	}
}
