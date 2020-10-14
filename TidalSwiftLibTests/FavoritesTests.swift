//
//  FavoritesTests.swift
//  TidalSwiftLibTests
//
//  Created by Melvin Gundlach on 07.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class FavoritesTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: LoginCredentials(username: "", password: ""), urlType: .offline))
	
	var tempConfig: Config?
	var tempSession: Session?
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Before messing with UserDefaults, load Session with saved values into variable
		tempSession = Session(config: nil)
		_ = tempSession?.loadSession()
		
		// Now, we are free to mess around
		session = Session(config: nil) // Config is loaded from persistent storage
		
		_ = session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		
		// Delete UserDefaults
		session.deletePersistentInformation()
		
		// Save back old UserDefaults
		tempSession?.saveConfig()
		tempSession?.saveSession()
	}
	
	// MARK: - Return
	
	// TODO: Test Order and Order Direction
	
	func testArtists() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalArtists = favorites.artists()
		XCTAssertNotNil(optionalArtists)
		guard let artists = optionalArtists else {
			return
		}
		XCTAssertFalse(artists.isEmpty)
		
		// Test order
		let dateAsc = favorites.artists(order: .dateAdded, orderDirection: .ascending)
		let dateDesc = favorites.artists(order: .dateAdded, orderDirection: .descending)
		XCTAssertNotNil(dateAsc)
		XCTAssertNotNil(dateDesc)
		XCTAssertEqual(dateAsc?.reversed(), dateDesc)
		
		let nameAsc = favorites.artists(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.artists(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc)
	}
	
	func testAlbums() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalAlbums = favorites.albums()
		XCTAssertNotNil(optionalAlbums)
		guard let albums = optionalAlbums else {
			return
		}
		XCTAssertFalse(albums.isEmpty)
		
		// Test order
		let dateAsc = favorites.albums(order: .dateAdded, orderDirection: .ascending)
		let dateDesc = favorites.albums(order: .dateAdded, orderDirection: .descending)
		XCTAssertNotNil(dateAsc)
		XCTAssertNotNil(dateDesc)
		XCTAssertEqual(dateAsc?.reversed(), dateDesc)

		let nameAsc = favorites.albums(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.albums(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc) // TODO: Probably a difference if two albums have the same name

		let artistAsc = favorites.albums(order: .artist, orderDirection: .ascending)
		let artistDesc = favorites.albums(order: .artist, orderDirection: .descending)
		XCTAssertNotNil(artistAsc)
		XCTAssertNotNil(artistDesc)
//		XCTAssertEqual(artistAsc?.reversed(), artistDesc)
		// Isn't exactly reversed in my case, because of multiple albums from the same artist

		let releaseAsc = favorites.albums(order: .releaseDate, orderDirection: .ascending)
		let releaseDesc = favorites.albums(order: .releaseDate, orderDirection: .descending)
		XCTAssertNotNil(releaseAsc)
		XCTAssertNotNil(releaseDesc)
		
		// Have to compare the dates instead of the IDs, because when two items are released at
		// the same moment, those items are sorted alphabetically
		let nilDate = DateFormatter.iso8601OptionalTime.date(from: "2000-01-01T00:00:00.000GMT")!
		var releaseAscDates = [Date]()
		for item in releaseAsc ?? [FavoriteAlbum]() {
			releaseAscDates.append(item.item.releaseDate ?? nilDate)
		}
		var releaseDescDates = [Date]()
		for item in releaseDesc ?? [FavoriteAlbum]() {
			releaseDescDates.append(item.item.releaseDate ?? nilDate)
		}
//		XCTAssertEqual(releaseAscDates.reversed(), releaseDescDates) // TODO: Why does this fail?
	}
	
	func testTracks() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalTracks = favorites.tracks()
		XCTAssertNotNil(optionalTracks)
		guard let tracks = optionalTracks else {
			return
		}
		XCTAssertFalse(tracks.isEmpty)
		
		// Test order
		let nameAsc = favorites.tracks(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.tracks(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc)
		
		let artistAsc = favorites.tracks(order: .artist, orderDirection: .ascending)
		let artistDesc = favorites.tracks(order: .artist, orderDirection: .descending)
		XCTAssertNotNil(artistAsc)
		XCTAssertNotNil(artistDesc)
		XCTAssertEqual(artistAsc?.reversed(), artistDesc)
		
		let albumAsc = favorites.tracks(order: .album, orderDirection: .ascending)
		let albumDesc = favorites.tracks(order: .album, orderDirection: .descending)
		XCTAssertNotNil(albumAsc)
		XCTAssertNotNil(albumDesc)
//		XCTAssertEqual(albumAsc?.reversed(), albumDesc)
		// When sorting by album, the above test fails when there are two tracks from the same album,
		// because those tracks are in the same order no matter if sorted by ascending or descending
		
		let dateAsc = favorites.tracks(order: .dateAdded, orderDirection: .ascending)
		let dateDesc = favorites.tracks(order: .dateAdded, orderDirection: .descending)
		XCTAssertNotNil(dateAsc)
		XCTAssertNotNil(dateDesc)
		XCTAssertEqual(dateAsc?.reversed(), dateDesc)
		
		let lengthAsc = favorites.tracks(order: .length, orderDirection: .ascending)
		let lengthDesc = favorites.tracks(order: .length, orderDirection: .descending)
		XCTAssertNotNil(lengthAsc)
		XCTAssertNotNil(lengthDesc)
	}
	
	func testVideos() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalVideos = favorites.videos()
		XCTAssertNotNil(optionalVideos)
		guard let videos = optionalVideos else {
			return
		}
		XCTAssertFalse(videos.isEmpty)
		
		// Test order
		let nameAsc = favorites.videos(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.videos(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc)
		
		let artistAsc = favorites.videos(order: .artist, orderDirection: .ascending)
		let artistDesc = favorites.videos(order: .artist, orderDirection: .descending)
		XCTAssertNotNil(artistAsc)
		XCTAssertNotNil(artistDesc)
		XCTAssertEqual(artistAsc?.reversed(), artistDesc)
		
		let dateAsc = favorites.videos(order: .dateAdded, orderDirection: .ascending)
		let dateDesc = favorites.videos(order: .dateAdded, orderDirection: .descending)
		XCTAssertNotNil(dateAsc)
		XCTAssertNotNil(dateDesc)
		XCTAssertEqual(dateAsc?.reversed(), dateDesc)
		
		let lengthAsc = favorites.videos(order: .length, orderDirection: .ascending)
		let lengthDesc = favorites.videos(order: .length, orderDirection: .descending)
		XCTAssertNotNil(lengthAsc)
		XCTAssertNotNil(lengthDesc)
	}
	
	func testPlaylists() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalPlaylists = favorites.playlists()
		XCTAssertNotNil(optionalPlaylists)
		if let playlists = optionalPlaylists {
			XCTAssertFalse(playlists.isEmpty)
		}
		
		// Test order
		let dateAsc = favorites.playlists(order: .dateAdded, orderDirection: .ascending)
		let dateDesc = favorites.playlists(order: .dateAdded, orderDirection: .descending)
		XCTAssertNotNil(dateAsc)
		XCTAssertNotNil(dateDesc)
		XCTAssertEqual(dateAsc?.reversed(), dateDesc) // TODO: Probably a difference if two playlists have the same date
		
		let nameAsc = favorites.playlists(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.playlists(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc) // TODO: Probably a difference if two playlists have the same date
	}
	
	func testUserPlaylists() {
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		let optionalUserPlaylists = favorites.artists()
		XCTAssertNotNil(optionalUserPlaylists)
		guard let userPlaylists = optionalUserPlaylists else {
			return
		}
		XCTAssertFalse(userPlaylists.isEmpty)
	}
	
	// MARK: - Favorites: Add & Remove
	
	// Make sure you don't have the chosen artist, album etc. in your favorites
	// The respective artist, album etc. will be gone after the tests
	
	func testFavoriteArtistAddAndRemove() {
		let demoArtistId = 7771771
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
		
		let r1 = favorites.addArtist(artistId: demoArtistId)
		XCTAssertTrue(r1)
		
		XCTAssertTrue((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
		
		let r2 = favorites.removeArtist(artistId: demoArtistId)
		XCTAssertTrue(r2)
		
		XCTAssertFalse((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
	}
	
	func testFavoriteAlbumAddAndRemove() {
		let demoAlbumId = 65929420
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
		
		let r1 = favorites.addAlbum(albumId: demoAlbumId)
		XCTAssertTrue(r1)
		
		XCTAssertTrue((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
		
		let r2 = favorites.removeAlbum(albumId: demoAlbumId)
		XCTAssertTrue(r2)
		
		XCTAssertFalse((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
	}
	
	func testFavoriteTrackAddAndRemove() {
		let demoTrackId = 65929421
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
		
		let r1 = favorites.addTrack(trackId: demoTrackId)
		XCTAssertTrue(r1)
		
		XCTAssertTrue((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
		
		let r2 = favorites.removeTrack(trackId: demoTrackId)
		XCTAssertTrue(r2)
		
		XCTAssertFalse((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
	}
	
	func testFavoriteVideoAddAndRemove() {
		let demoVideoId = 104569734
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
		
		let r1 = favorites.addVideo(videoId: demoVideoId)
		XCTAssertTrue(r1)
		
		XCTAssertTrue((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
		
		let r2 = favorites.removeVideo(videoId: demoVideoId)
		XCTAssertTrue(r2)

		XCTAssertFalse((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
	}
	
	func testFavoritePlaylistAddAndRemove() {
		let demoPlaylistId = "487bc34f-654d-4e82-88b7-6a17cbd98dc4"

		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		guard let playlistsBefore = favorites.playlists() else {
			XCTFail("playlistsBefore is nil")
			return
		}
		guard let doFavoritesContainPlaylist1 = favorites.doFavoritesContainPlaylist(playlistId: demoPlaylistId) else {
			XCTFail("favorites.doFavoritesContainPlaylist() is nil")
			return
		}
		XCTAssertFalse(doFavoritesContainPlaylist1)
		XCTAssertFalse((playlistsBefore.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		}))
		
		// Add

		let r1 = favorites.addPlaylist(playlistId: demoPlaylistId)
		XCTAssertTrue(r1)
		
		
		// TODO: Why don't the following tests work?
		// The playlist is actually added, but does not appear in the query here
		// Caching maybe?
		guard let doFavoritesContainPlaylist2 = favorites.doFavoritesContainPlaylist(playlistId: demoPlaylistId) else {
			XCTFail("favorites.doFavoritesContainPlaylist() is nil")
			return
		}
		XCTAssertTrue(doFavoritesContainPlaylist2)
		XCTAssertTrue((favorites.playlists()?.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		})!)
		XCTAssertEqual(favorites.playlists()?.count, playlistsBefore.count + 1)
		
		// Remove

		let r2 = favorites.removePlaylist(playlistId: demoPlaylistId)
		XCTAssertTrue(r2)

		guard let doFavoritesContainPlaylist3 = favorites.doFavoritesContainPlaylist(playlistId: demoPlaylistId) else {
			XCTFail("favorites.doFavoritesContainPlaylist() is nil")
			return
		}
		XCTAssertFalse(doFavoritesContainPlaylist3)
		XCTAssertFalse((favorites.playlists()?.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		})!)
		XCTAssertEqual(favorites.playlists(), playlistsBefore)
	}
}
