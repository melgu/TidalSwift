//
//  Helpers.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

struct DownloadError {
	var affectedTracks = [Track]()
	var affectedAlbums = [Album]()
	var affectedArtists = [Artist]()
	var affectedPlaylists = [Playlist]()
}

class Helpers {
	unowned let session: Session
	let offline: Offline
	
	init(session: Session) {
		self.session = session
		self.offline = Offline(session: session)
	}
	
	func newReleasesFromFavoriteArtists(number: Int = 30) -> [Album]? {
		let optionalFavoriteArtists = session.favorites?.artists()
		guard let favoriteArtists = optionalFavoriteArtists else {
			return nil
		}
		
		var allReleases = [Album]()
		for artist in favoriteArtists {
			let optionalAlbums = session.getArtistAlbums(artistId: artist.item.id, limit: number)
			guard let albums = optionalAlbums else {
				continue
			}
			allReleases += albums
		}
		
		allReleases.sort { $0.releaseDate! > $1.releaseDate! }
		return Array(allReleases.prefix(number))
	}
	
	// MARK: - Downloading
	
	// TODO: Titles can be a names which the file system doesn't like
	// TODO: Currently everything is done on the main thread synchronously
	
	func formFileName(_ track: Track) -> String {
		return "\(track.trackNumber) \(track.title) - \(track.artists.map({ $0.name }).joined(separator: ", ")).m4a"
	}
	
	func formFileName(_ video: Video) -> String {
		return "\(video.trackNumber) \(video.title) - \(video.artists.map({ $0.name }).joined(separator: ", ")).mp4"
	}
	
	func downloadTrack(track: Track, parentFolder: String = "") -> Bool {
		guard let url = session.getAudioUrl(trackId: track.id) else { return false }
		print("Downloading \(track.title)")
		let response = Network.download(url, baseLocation: .downloads, targetPath: parentFolder, name: formFileName(track))
		// TODO: Name should include all artists, not just the first
		return response.ok
	}
	
	func downloadVideo(video: Video, parentFolder: String = "") -> Bool {
		guard let url = session.getVideoUrl(videoId: video.id) else { return false }
		let response = Network.download(url, baseLocation: .downloads, targetPath: parentFolder, name: formFileName(video))
		// TODO: Name should include all artists, not just the first
		return response.ok
	}
	
	func downloadAlbum(album: Album, parentFolder: String = "") -> DownloadError {
		guard let tracks = session.getAlbumTracks(albumId: album.id) else { return DownloadError(affectedAlbums: [album]) }
		var error = DownloadError()
		for track in tracks {
			let r = downloadTrack(track: track, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(album.title)")
			if !r {
				error.affectedTracks.append(track)
			}
		}
		return error
	}
	
	func downloadAllAlbumsFromArtist(artist: Artist, parentFolder: String = "") -> DownloadError {
		guard let albums = session.getArtistAlbums(artistId: artist.id) else { return DownloadError(affectedArtists: [artist]) }
		var error = DownloadError()
		for album in albums {
			let r = downloadAlbum(album: album, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(artist.name)")
			error.affectedAlbums.append(contentsOf: r.affectedAlbums)
			error.affectedTracks.append(contentsOf: r.affectedTracks)
		}
		return error
	}
	
	func downloadPlaylist(playlist: Playlist, parentFolder: String = "") -> DownloadError {
		guard let tracks = session.getPlaylistTracks(playlistId: playlist.uuid) else { return DownloadError(affectedPlaylists: [playlist]) }
		var error = DownloadError()
		for track in tracks {
			let r = downloadTrack(track: track, parentFolder: "\(parentFolder.isEmpty ? "" : "\(parentFolder)/")\(playlist.title)")
			if !r {
				error.affectedTracks.append(track)
			}
		}
		return error
	}
}

// MARK: - Offline

class Offline {
	unowned let session: Session
	let mainPath = "TidalSwift Offline Library"
	
	init(session: Session) {
		self.session = session
		
		// Create main folder if it doesn't exist
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		} catch {
			displayError(title: "Error while creating Offline management class", content: "Error: \(error)")
		}
	}
	
	func addTrack(trackId: Int) -> Bool {
		guard let url = session.getAudioUrl(trackId: trackId) else {
			return false
		}
		let response = Network.download(url, baseLocation: .music, targetPath: mainPath, name: String(trackId))
		return response.ok
	}
	
	// Warning: Does not check if song is still needed present in other offline album, playlist or other
	func removeTrack(trackId: Int) {
		do {
			var path = try FileManager.default.url(for: .musicDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(mainPath)
			path.appendPathComponent(String(trackId))
			if FileManager.default.fileExists(atPath: path.relativePath) {
				try FileManager.default.removeItem(at: path)
			}
		} catch {
			displayError(title: "Error while removing Offline track", content: "Error: \(error)")
		}
	}

}
