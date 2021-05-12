//
//  Metadata.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 30.06.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftTagger

class Metadata {
	unowned let session: Session
	
	init(session: Session) {
		self.session = session
	}
	
	func setMetadata(for track: Track, at path: URL) {
		print("FIXME: Set Metadata") // FIXME: Set Metadata
		
		var m4aFile: AudioFile
		do {
			m4aFile = try AudioFile(location: path)
		} catch {
			displayError(title: "Error finding M4A file", content: "Path: \(path). Error: \(error)")
			return
		}
		
		var title = track.title
		if let version = track.version {
			title += " (\(version))"
		}
		m4aFile.title = title
		
		if !track.artists.isEmpty {
			m4aFile.artist = track.artists.formArtistString()
		}
		
		
		m4aFile.album = track.album.title
		
		if let album = session.getAlbum(albumId: track.album.id) {
			m4aFile.discNumber = .init(index: track.volumeNumber, total: album.numberOfVolumes)
			
			m4aFile.trackNumber = .init(index: track.trackNumber, total: album.numberOfTracks)
			
			if let artists = album.artists, !artists.isEmpty {
				m4aFile.albumArtist = artists.formArtistString()
			}
		}
		
		m4aFile.releaseDateTime = track.album.releaseDate

		m4aFile.copyright = track.copyright
		
		if let coverUrl = track.getCoverUrl(session: session, resolution: 1280) {
			do {
				try m4aFile.setCoverArt(imageLocation: coverUrl)
			} catch {
				displayError(title: "Error setting cover art", content: "Error: \(error)")
				return
			}
		}

		// TODO: Content rating
//		if track.explicit {
//			 m4aFile.contentRating = .
//		}

		// TODO: Check if correct
		m4aFile.compilation = track.album.isCompilation
		
		// iTunes Artist ID
		m4aFile.artistID = track.artist?.id
		
		do {
			try m4aFile.write(outputLocation: path)
		} catch {
			displayError(title: "Error writing Metadata", content: "Path: \(path). Error: \(error)")
			return
		}
	}
}
