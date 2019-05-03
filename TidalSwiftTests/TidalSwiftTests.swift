//
//  TidalSwiftTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 21.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwift

class TidalSwiftTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	
	var tempConfig: Config?
	var tempSession: Session?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Before messing with UserDefaults, load Session with saved values into variable
		tempSession = Session(config: nil)
		tempSession?.loadSession()
		
		// Now, we are free to mess around
		let config = Config(quality: .hifi, loginCredentials: readDemoLoginCredentials())
		session = Session(config: config)
		
		session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		
		// Delete messed-with UserDefaults
		session.deletePersistantInformation()
		
		// Save back old UserDefaults
		tempSession?.saveConfig()
		tempSession?.saveSession()
    }
	
	func testSaveAndLoadSession() {
		let tempSessionId = session.sessionId
		let tempCountryCode = session.countryCode
		let tempUserId = session.userId
		
		session.saveSession()
		session.loadSession()
		
		XCTAssertEqual(tempSessionId, session.sessionId)
		XCTAssertEqual(tempCountryCode, session.countryCode)
		XCTAssertEqual(tempUserId, session.userId)
	}
	
	func testSaveAndLoadConfig() {
		let oldConfig = session.config
		session.saveConfig()
		session = Session(config: nil)
		
		XCTAssertEqual(oldConfig.quality, session.config.quality)
		XCTAssertEqual(oldConfig.apiLocation, session.config.apiLocation)
		XCTAssertEqual(oldConfig.apiToken, session.config.apiToken)
		XCTAssertEqual(oldConfig.imageUrl, session.config.imageUrl)
		XCTAssertEqual(oldConfig.imageSize, session.config.imageSize)
	}
	
	// Login Testing commented out to prevent potential ban from the server if done too often
//	func testLogin() {
//		let loginInfo = readDemoLoginCredentials()
//		let config = Config(quality: .hifi, loginCredentials: loginInfo)
//		session = Session(config: config)
//		let result = session.login()
//		XCTAssert(result)
//	}
//
//	func testWrongLogin() {
//		// Wrong Login Info
//		let loginInfo1 = LoginCredentials(username: "ABC", password: "ABC")
//		let config1 = Config(quality: .hifi, loginCredentials: loginInfo1)
//		session = Session(config: config1)
//		let result1 = session.login()
//		XCTAssertFalse(result1)
//
//		// Empty Login Info
//		let loginInfo2 = LoginCredentials(username: "", password: "")
//		let config2 = Config(quality: .hifi, loginCredentials: loginInfo2)
//		session = Session(config: config2)
//		let result2 = session.login()
//		XCTAssertFalse(result2)
//	}
	
	func testCheckLogin() {
		XCTAssert(session.checkLogin())
		
		let loginCredentials = LoginCredentials(username: "", password: "")
		let config = Config(quality: .hifi, loginCredentials: loginCredentials)
		session = Session(config: config)
		
		XCTAssertFalse(session.checkLogin())
	}
	
	func testGetSubscriptionInfo() {
		let info = session.getSubscriptionInfo()
		XCTAssertNotNil(info)
		
		// Values are highly dependent on own subscription type.
		// Values here are for an account inside a HIFI Family plan.
		XCTAssertEqual(info?.status, "ACTIVE")
		XCTAssertEqual(info?.subscription.type, "HIFI")
		XCTAssertEqual(info?.subscription.offlineGracePeriod, 30)
		XCTAssertEqual(info?.highestSoundQuality, .hifi) // "LOSSLESS" although Master is possible
		XCTAssertEqual(info?.premiumAccess, true)
		XCTAssertEqual(info?.canGetTrial, false)
		XCTAssertEqual(info?.paymentType, "PARENT")
	}
	
	// Stops playback if you're listening in the web player or official app
//	func testGetMediaUrl() {
//		let trackUrl = session.getAudioUrl(trackId: 59978883)
//		XCTAssertNotNil(trackUrl)
//		print(trackUrl)
//	}
	
	// Stops playback if you're listening in the web player or official app
//	func testGetVideoUrl() {
//		let videoUrl = session.getVideoUrl(videoId: 98785108)
//		XCTAssertNotNil(videoUrl)
//		print(videoUrl)
//	}
	
	func testSearchArtist() {
		let searchResult = session.search(for: "Jacob Collier")
		XCTAssertEqual(searchResult?.artists.totalNumberOfItems, 1)
		XCTAssertEqual(searchResult?.artists.items[0].id, 7553669)
		XCTAssertEqual(searchResult?.artists.items[0].name, "Jacob Collier")
		XCTAssertEqual(searchResult?.artists.items[0].url,
					   URL(string: "http://www.tidal.com/artist/7553669"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(searchResult?.artists.items[0].picture,
					   "daaa931c-afc0-4c63-819c-c821393b6a45")
		XCTAssertNotNil(searchResult?.artists.items[0].popularity)
		XCTAssertNil(searchResult?.artists.items[0].type)
		XCTAssertNil(searchResult?.artists.items[0].banner)
		XCTAssertNil(searchResult?.artists.items[0].relationType)
	}
	
	func testSearchAlbum() {
		let searchResult = session.search(for: "Jacob Collier Djesse Vol. 1")
		XCTAssertEqual(searchResult?.albums.totalNumberOfItems, 2)
		
		// Master Version
		XCTAssertEqual(searchResult?.albums.items[0].id, 100006868)
		XCTAssertEqual(searchResult?.albums.items[0].title, "Djesse (Vol. 1)")
		XCTAssertEqual(searchResult?.albums.items[0].duration, 3196)
		XCTAssertEqual(searchResult?.albums.items[0].streamReady, true)
		XCTAssertEqual(searchResult?.albums.items[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(searchResult?.albums.items[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfTracks, 9)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfVideos, 0)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfVolumes, 1)
		XCTAssertEqual(searchResult?.albums.items[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(searchResult?.albums.items[0].copyright,
					   "© 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertNotNil(searchResult?.albums.items[0].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].audioQuality, .master)
		
		// HiFi Version
		XCTAssertEqual(searchResult?.albums.items[1].audioQuality, .hifi)
		
		// Album Artists
		XCTAssertEqual(searchResult?.albums.items[0].artists?.count, 3)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].id, 7553669)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].name, "Jacob Collier")
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].url)
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].picture)
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].type, "MAIN")
		
		XCTAssertEqual(searchResult?.albums.items[0].artists?[1].id, 4631340)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[1].name, "Metropole Orkest")
		XCTAssertNil(searchResult?.albums.items[0].artists?[1].url)
		XCTAssertNil(searchResult?.albums.items[0].artists?[1].picture)
		XCTAssertNil(searchResult?.albums.items[0].artists?[1].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[1].type, "MAIN")
		
		XCTAssertEqual(searchResult?.albums.items[0].artists?[2].id, 4374293)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[2].name, "Jules Buckley")
		XCTAssertNil(searchResult?.albums.items[0].artists?[2].url)
		XCTAssertNil(searchResult?.albums.items[0].artists?[2].picture)
		XCTAssertNil(searchResult?.albums.items[0].artists?[2].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[2].type, "MAIN")
	}
	
	func testSearchPlaylist() {
		let searchResult = session.search(for: "Barack Obama Speeches")
		XCTAssertEqual(searchResult?.playlists.totalNumberOfItems, 1)
		XCTAssertEqual(searchResult?.playlists.items.count, 1)
		XCTAssertEqual(searchResult?.playlists.items[0].uuid,
					   "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		XCTAssertEqual(searchResult?.playlists.items[0].title, "Barack Obama Speeches")
		XCTAssertEqual(searchResult?.playlists.items[0].numberOfTracks, 20)
		XCTAssertEqual(searchResult?.playlists.items[0].numberOfVideos, 0)
		let description = "Grab inspiration from this collection of No. 44's notable speeches. "
		XCTAssertEqual(searchResult?.playlists.items[0].description, description)
		XCTAssertEqual(searchResult?.playlists.items[0].duration, 34170)
		XCTAssertEqual(searchResult?.playlists.items[0].lastUpdated,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2019-02-28T21:14:54.000GMT"))
		XCTAssertEqual(searchResult?.playlists.items[0].created,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-01-19T17:56:03.000GMT"))
		XCTAssertEqual(searchResult?.playlists.items[0].type, .editorial)
		// Here it's false, but in the Playlist test it's true. No idea, why.
		XCTAssertEqual(searchResult?.playlists.items[0].publicPlaylist, false)
		XCTAssertEqual(searchResult?.playlists.items[0].url, URL(string:
			"http://www.tidal.com/playlist/96696a2c-b284-4dd3-8e51-5e0dae44ace0"))
		XCTAssertEqual(searchResult?.playlists.items[0].image,
					   "43f8e4db-769c-40f6-b561-99609aef0c13")
//		print(searchResult?.playlists.items[0].popularity)
		XCTAssertEqual(searchResult?.playlists.items[0].squareImage,
					   "50fbe933-0049-4e0e-be82-2de70b19168e")
	}
	
	func testSearchTrack() {
		let searchResult = session.search(for: "Jacob Collier In My Room")
		XCTAssertEqual(searchResult?.tracks.totalNumberOfItems, 1)
		XCTAssertEqual(searchResult?.tracks.items.count, 1)
		XCTAssertEqual(searchResult?.tracks.items[0].id, 59978883)
		XCTAssertEqual(searchResult?.tracks.items[0].title, "In My Room")
		XCTAssertEqual(searchResult?.tracks.items[0].duration, 289)
		XCTAssertEqual(searchResult?.tracks.items[0].replayGain, -7.04)
		XCTAssertEqual(searchResult?.tracks.items[0].peak, 0.944366)
		XCTAssertEqual(searchResult?.tracks.items[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.tracks.items[0].streamReady, true)
		XCTAssertEqual(searchResult?.tracks.items[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-01"))
		XCTAssertEqual(searchResult?.tracks.items[0].trackNumber, 2)
		XCTAssertEqual(searchResult?.tracks.items[0].volumeNumber, 1)
//		print(searchResult?.tracks.items[0].popularity)
		XCTAssertEqual(searchResult?.tracks.items[0].copyright, "2016 Membran")
		XCTAssertEqual(searchResult?.tracks.items[0].url,
					   URL(string: "http://www.tidal.com/track/59978883"))
		XCTAssertEqual(searchResult?.tracks.items[0].isrc, "US23A1500084")
		XCTAssertEqual(searchResult?.tracks.items[0].editable, true)
		XCTAssertEqual(searchResult?.tracks.items[0].explicit, false)
		XCTAssertEqual(searchResult?.tracks.items[0].audioQuality, .hifi)
		
		// Artists
		XCTAssertEqual(searchResult?.tracks.items[0].artists.count, 1)
		XCTAssertEqual(searchResult?.tracks.items[0].artists[0].id, 7553669)
		XCTAssertEqual(searchResult?.tracks.items[0].artists[0].name, "Jacob Collier")
//		print(searchResult?.videos.items[0].artists[0].type) // For no reason "Index out of range"
//		XCTAssertEqual(searchResult?.videos.items[0].artists[0].type, "MAIN")
		
		// Album
		XCTAssertEqual(searchResult?.tracks.items[0].album.id, 59978881)
		XCTAssertEqual(searchResult?.tracks.items[0].album.title, "In My Room")
	}
	
	func testSearchVideo() {
		let searchResult = session.search(for:
			"Jacob Collier With The Love In My Heart")
		XCTAssertEqual(searchResult?.videos.totalNumberOfItems, 1)
		XCTAssertEqual(searchResult?.videos.items[0].id, 98785108)
		XCTAssertEqual(searchResult?.videos.items[0].title,
					   "With The Love In My Heart")
		XCTAssertEqual(searchResult?.videos.items[0].volumeNumber, 1)
		XCTAssertEqual(searchResult?.videos.items[0].trackNumber, 1)
		XCTAssertEqual(searchResult?.videos.items[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-11-16"))
		XCTAssertNil(searchResult?.videos.items[0].imagePath)
		XCTAssertEqual(searchResult?.videos.items[0].imageId,
					   "94cf59fb-2816-4c40-989d-8aff2365baf9")
		XCTAssertEqual(searchResult?.videos.items[0].duration, 406)
		XCTAssertEqual(searchResult?.videos.items[0].quality, "MP4_1080P")
		XCTAssertEqual(searchResult?.videos.items[0].streamReady, true)
		XCTAssertEqual(searchResult?.videos.items[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-11-16T18:00:00.000GMT"))
		XCTAssertEqual(searchResult?.videos.items[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.videos.items[0].explicit, false)
//		print(searchResult?.videos.items[0].popularity)
		XCTAssertEqual(searchResult?.videos.items[0].type, "Music Video")
		XCTAssertNil(searchResult?.videos.items[0].adsUrl)
		XCTAssertEqual(searchResult?.videos.items[0].adsPrePaywallOnly, true)
		
		// Artists
		XCTAssertEqual(searchResult?.tracks.items[0].artists.count, 3)
		
		XCTAssertEqual(searchResult?.tracks.items[0].artists[0].id, 7553669)
		XCTAssertEqual(searchResult?.tracks.items[0].artists[0].name, "Jacob Collier")
		XCTAssertEqual(searchResult?.videos.items[0].artists[0].type, "MAIN")
		
		XCTAssertEqual(searchResult?.tracks.items[0].artists[1].id, 4631340)
		XCTAssertEqual(searchResult?.tracks.items[0].artists[1].name, "Metropole Orkest")
		XCTAssertEqual(searchResult?.videos.items[0].artists[1].type, "MAIN")
		
		XCTAssertEqual(searchResult?.tracks.items[0].artists[2].id, 4374293)
		XCTAssertEqual(searchResult?.tracks.items[0].artists[2].name, "Jules Buckley")
		XCTAssertEqual(searchResult?.videos.items[0].artists[2].type, "MAIN")
		
		// Album (probably need to find a better example)
		XCTAssertNil(searchResult?.videos.items[0].album)
		
	}
	
	func testSearchTopHit() {
		// Artist
		let searchResultArtist = session.search(for: "Jacob Collier")
		XCTAssertEqual(searchResultArtist?.topHit?.value.id, 7553669)
		XCTAssertNil(searchResultArtist?.topHit?.value.uuid)
//		print(searchResult?.topHit?.value.popularity)
		
		// Album
		let searchResultAlbum = session.search(for: "Jacob Collier In My Room")
		XCTAssertEqual(searchResultAlbum?.topHit?.value.id, 59978881)
		XCTAssertNil(searchResultAlbum?.topHit?.value.uuid)
//		print(searchResult?.topHit?.value.popularity)
		
		// Playlist
		let searchResultPlaylist = session.search(for: "Awesome Jazz")
		XCTAssertNil(searchResultPlaylist?.topHit?.value.id)
		XCTAssertEqual(searchResultPlaylist?.topHit?.value.uuid, "a784a00e-8f76-4a67-8624-656a1e80f7ed")
//		print(searchResult?.topHit?.value.popularity)
		
		// Track
		let searchResultTrack = session.search(for: "Britney Toxic")
		XCTAssertEqual(searchResultTrack?.topHit?.value.id, 42298)
		XCTAssertNil(searchResultTrack?.topHit?.value.uuid)
//		print(searchResult?.topHit?.value.popularity)
	}
	
	func testSearchLimitAndOffset() {
		let searchResult = session.search(for: "Rolf Zuckowski")
		XCTAssertEqual(searchResult?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResult?.tracks.limit, 50)
		XCTAssertEqual(searchResult?.tracks.items.count, 50)
		XCTAssertEqual(searchResult?.tracks.offset, 0)
		
		// Test Offset
		let searchResultWithOffset = session.search(for: "Rolf Zuckowski", offset: 1)
		XCTAssertEqual(searchResultWithOffset?.tracks.limit, 50)
		XCTAssertEqual(searchResultWithOffset?.tracks.offset, 1)
		
		XCTAssertEqual(searchResult?.tracks.totalNumberOfItems, 300)
		
		// Test Limit
		let searchResultWithLimit = session.search(for: "Rolf Zuckowski", limit: 5)
		XCTAssertEqual(searchResultWithLimit?.tracks.limit, 5)
		XCTAssertEqual(searchResultWithLimit?.tracks.offset, 0)
		
		XCTAssertEqual(searchResult?.tracks.totalNumberOfItems, 300)
		
		// Test Big Offset
		let searchResultWithBigOffset1 = session.search(for: "Rolf Zuckowski", offset: 301)
		XCTAssertEqual(searchResultWithBigOffset1?.tracks.limit, 50)
		XCTAssertEqual(searchResultWithBigOffset1?.tracks.offset, 301)
		XCTAssertEqual(searchResultWithBigOffset1?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResultWithBigOffset1?.tracks.items.count, 0)
		
		let searchResultWithBigOffset2 = session.search(for: "Rolf Zuckowski", offset: 275)
		XCTAssertEqual(searchResultWithBigOffset2?.tracks.limit, 50)
		XCTAssertEqual(searchResultWithBigOffset2?.tracks.offset, 275)
		XCTAssertEqual(searchResultWithBigOffset2?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResultWithBigOffset2?.tracks.items.count, 25)
		
		// Test High Limit
		let searchResultWithHighLimit = session.search(for: "Rolf Zuckowski", limit: 500)
		XCTAssertEqual(searchResultWithHighLimit?.tracks.limit, 500)
		XCTAssertEqual(searchResultWithHighLimit?.tracks.offset, 0)
		XCTAssertEqual(searchResultWithHighLimit?.tracks.items.count, 300)
		XCTAssertEqual(searchResultWithHighLimit?.tracks.totalNumberOfItems, 300)
	}
	
	func testGetPlaylist() {
		let playlist = session.getPlaylist(playlistId: "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		
		XCTAssertEqual(playlist?.uuid, "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		XCTAssertEqual(playlist?.title, "Barack Obama Speeches")
		XCTAssertEqual(playlist?.numberOfTracks, 20)
		XCTAssertEqual(playlist?.numberOfVideos, 0)
		let description = "Grab inspiration from this collection of No. 44's notable speeches. "
		XCTAssertEqual(playlist?.description, description)
		XCTAssertEqual(playlist?.duration, 34170)
		XCTAssertEqual(playlist?.lastUpdated,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2019-02-28T21:14:54.402GMT"))
		XCTAssertEqual(playlist?.created,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-01-19T17:56:03.125GMT"))
		XCTAssertEqual(playlist?.type, .editorial)
		XCTAssertEqual(playlist?.publicPlaylist, true)
		// Here it's true, but in the Search test it's false. No idea, why.
		XCTAssertEqual(playlist?.url, URL(string:
			"http://www.tidal.com/playlist/96696a2c-b284-4dd3-8e51-5e0dae44ace0"))
		XCTAssertEqual(playlist?.image, "43f8e4db-769c-40f6-b561-99609aef0c13")
//		print(searchResult?.playlists.items[0].popularity)
		XCTAssertEqual(playlist?.squareImage, "50fbe933-0049-4e0e-be82-2de70b19168e")
		
		// Playlist Creator (TIDAL Editorial)
		XCTAssertEqual(playlist?.creator.id, 0)
		XCTAssertNil(playlist?.creator.name)
		XCTAssertNil(playlist?.creator.picture)
		XCTAssertNil(playlist?.creator.popularity)
		XCTAssertNil(playlist?.creator.url)
		
		
		// Testing with Billboard Playlist
		let playlist2 = session.getPlaylist(playlistId: "a6223536-93b8-4d21-b35a-59d4246bf962")
		XCTAssertEqual(playlist2?.title, "Billboard Hot 100")
		XCTAssertEqual(playlist2?.numberOfTracks, 100)
		XCTAssertEqual(playlist?.type, .editorial)
		
		// Playlist Creator (Billboard)
		XCTAssertEqual(playlist2?.creator.id, 0)
		XCTAssertEqual(playlist2?.creator.name, "Billboard")
		XCTAssertNil(playlist2?.creator.picture)
		XCTAssertNil(playlist2?.creator.popularity)
		XCTAssertNil(playlist2?.creator.url)
	}

	func testGetPlaylistTracks() {
		let optionalPlaylistTracks = session.getPlaylistTracks(playlistId: "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		XCTAssertNotNil(optionalPlaylistTracks)
		guard let playlistTracks = optionalPlaylistTracks else {
			return
		}
		
		XCTAssertEqual(playlistTracks.count, 20) // Only 19 visible, at least in Germany
		
		XCTAssertEqual(playlistTracks[0].id, 9312527)
		XCTAssertEqual(playlistTracks[0].title, "Iowa Caucus Victory Speech")
		XCTAssertEqual(playlistTracks[0].duration, 777)
		XCTAssertEqual(playlistTracks[0].replayGain, -8.13)
		XCTAssertEqual(playlistTracks[0].peak, 1.0)
		XCTAssertEqual(playlistTracks[0].allowStreaming, true)
		XCTAssertEqual(playlistTracks[0].streamReady, true)
		XCTAssertEqual(playlistTracks[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2009-02-01"))
		XCTAssertEqual(playlistTracks[0].premiumStreamingOnly, false)
		XCTAssertEqual(playlistTracks[0].trackNumber, 22)
		XCTAssertEqual(playlistTracks[0].volumeNumber, 1)
		XCTAssertNil(playlistTracks[0].version)
//		print(playlistTracks[0].popularity)
		XCTAssertEqual(playlistTracks[0].copyright, "2009 Master Classics Records")
		XCTAssertEqual(playlistTracks[0].url, URL(string:
			"http://www.tidal.com/track/9312527"))
		XCTAssertEqual(playlistTracks[0].isrc, "USA560912799")
		XCTAssertEqual(playlistTracks[0].editable, true)
		XCTAssertEqual(playlistTracks[0].explicit, false)
		XCTAssertEqual(playlistTracks[0].audioQuality, .hifi)
		XCTAssertEqual(playlistTracks[0].surroundTypes, [])
		XCTAssertEqual(playlistTracks[0].artist?.id, 3969810)
		XCTAssertEqual(playlistTracks[0].artist?.name, "Barack Obama")
		XCTAssertEqual(playlistTracks[0].artists.count, 1)
		XCTAssertEqual(playlistTracks[0].artists[0].id, 3969810)
		XCTAssertEqual(playlistTracks[0].artists[0].name, "Barack Obama")
		
		XCTAssertEqual(playlistTracks[19].id, 47393478)
		XCTAssertEqual(playlistTracks[19].title, "Yes We Did (feat. New Hampshire Primary Address)")
	}

	func testGetAlbum() {
		let album = session.getAlbum(albumId: 100006868)
		
		XCTAssertEqual(album?.id, 100006868)
		XCTAssertEqual(album?.title, "Djesse (Vol. 1)")
		XCTAssertEqual(album?.duration, 3196)
		XCTAssertEqual(album?.streamReady, true)
		XCTAssertEqual(album?.streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(album?.allowStreaming, true)
		XCTAssertEqual(album?.numberOfTracks, 9)
		XCTAssertEqual(album?.numberOfVideos, 0)
		XCTAssertEqual(album?.numberOfVolumes, 1)
		XCTAssertEqual(album?.releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(album?.copyright,
					   "© 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertNotNil(album?.popularity)
		XCTAssertEqual(album?.audioQuality, .master)
		
		// Album Artists
		XCTAssertEqual(album?.artists?.count, 3)
		XCTAssertEqual(album?.artists?[0].id, 7553669)
		XCTAssertEqual(album?.artists?[0].name, "Jacob Collier")
		XCTAssertNil(album?.artists?[0].url)
		XCTAssertNil(album?.artists?[0].picture)
		XCTAssertNil(album?.artists?[0].popularity)
		XCTAssertEqual(album?.artists?[0].type, "MAIN")
		
		XCTAssertEqual(album?.artists?[1].id, 4631340)
		XCTAssertEqual(album?.artists?[1].name, "Metropole Orkest")
		XCTAssertNil(album?.artists?[1].url)
		XCTAssertNil(album?.artists?[1].picture)
		XCTAssertNil(album?.artists?[1].popularity)
		XCTAssertEqual(album?.artists?[1].type, "MAIN")
		
		XCTAssertEqual(album?.artists?[2].id, 4374293)
		XCTAssertEqual(album?.artists?[2].name, "Jules Buckley")
		XCTAssertNil(album?.artists?[2].url)
		XCTAssertNil(album?.artists?[2].picture)
		XCTAssertNil(album?.artists?[2].popularity)
		XCTAssertEqual(album?.artists?[2].type, "MAIN")
	}

	func testGetAlbumTracks() {
		let optionalAlbumTracks = session.getAlbumTracks(albumId: 100006868)
		XCTAssertNotNil(optionalAlbumTracks)
		guard let albumTracks = optionalAlbumTracks else {
			return
		}
		
		XCTAssertEqual(albumTracks.count, 9)
		
		XCTAssertEqual(albumTracks[0].id, 100006869)
		XCTAssertEqual(albumTracks[0].title, "Home Is")
		XCTAssertEqual(albumTracks[0].duration, 345)
		XCTAssertEqual(albumTracks[0].replayGain, -5.94)
		XCTAssertEqual(albumTracks[0].peak, 0.999957)
		XCTAssertEqual(albumTracks[0].allowStreaming, true)
		XCTAssertEqual(albumTracks[0].streamReady, true)
		XCTAssertEqual(albumTracks[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(albumTracks[0].trackNumber, 1)
		XCTAssertEqual(albumTracks[0].volumeNumber, 1)
		//		print(albumTracks[0].popularity)
		XCTAssertEqual(albumTracks[0].copyright,
					   "℗ 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertEqual(albumTracks[0].url,
					   URL(string: "http://www.tidal.com/track/100006869"))
		XCTAssertEqual(albumTracks[0].isrc, "GBUM71807062")
		XCTAssertEqual(albumTracks[0].editable, false)
		XCTAssertEqual(albumTracks[0].explicit, false)
		XCTAssertEqual(albumTracks[0].audioQuality, .master)
		
		XCTAssertEqual(albumTracks[8].id, 100006880)
		XCTAssertEqual(albumTracks[8].title, "All Night Long")

		// Artists
		XCTAssertEqual(albumTracks[0].artists.count, 2)
		XCTAssertEqual(albumTracks[0].artists[0].id, 7553669)
		XCTAssertEqual(albumTracks[0].artists[0].name, "Jacob Collier")
		XCTAssertEqual(albumTracks[0].artists[0].type, "MAIN")
		
		XCTAssertEqual(albumTracks[0].artists[1].id, 4236852)
		XCTAssertEqual(albumTracks[0].artists[1].name, "Voces8")
		XCTAssertEqual(albumTracks[0].artists[1].type, "MAIN")

		// Album
		XCTAssertEqual(albumTracks[0].album.id, 100006868)
		XCTAssertEqual(albumTracks[0].album.title, "Djesse (Vol. 1)")
	}

	func testGetArtist() {
		let artist = session.getArtist(artistId: 7553669)
		
		XCTAssertEqual(artist?.id, 7553669)
		XCTAssertEqual(artist?.name, "Jacob Collier")
		XCTAssertEqual(artist?.url, URL(string:
			"http://www.tidal.com/artist/7553669"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(artist?.picture,
					   "daaa931c-afc0-4c63-819c-c821393b6a45")
		XCTAssertNotNil(artist?.popularity)
		XCTAssertNil(artist?.type)
		XCTAssertNil(artist?.banner)
		XCTAssertNil(artist?.relationType)
	}

	func testGetArtistAlbums() {
		let optionalArtistAlbums = session.getArtistAlbums(artistId: 7553669)
		XCTAssertNotNil(optionalArtistAlbums)
		guard let artistAlbums = optionalArtistAlbums else {
			return
		}
		
		XCTAssertEqual(artistAlbums[0].id, 100006868)
		XCTAssertEqual(artistAlbums[0].title, "Djesse (Vol. 1)")
		XCTAssertEqual(artistAlbums[0].duration, 3196)
		XCTAssertEqual(artistAlbums[0].streamReady, true)
		XCTAssertEqual(artistAlbums[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(artistAlbums[0].allowStreaming, true)
		XCTAssertEqual(artistAlbums[0].numberOfTracks, 9)
		XCTAssertEqual(artistAlbums[0].numberOfVideos, 0)
		XCTAssertEqual(artistAlbums[0].numberOfVolumes, 1)
		XCTAssertEqual(artistAlbums[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(artistAlbums[0].copyright,
					   "© 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertNotNil(artistAlbums[0].popularity)
		XCTAssertEqual(artistAlbums[0].audioQuality, .master)
		
		// Album Artists
		XCTAssertEqual(artistAlbums[0].artists?.count, 3)
		XCTAssertEqual(artistAlbums[0].artists?[0].id, 7553669)
		XCTAssertEqual(artistAlbums[0].artists?[0].name, "Jacob Collier")
		XCTAssertNil(artistAlbums[0].artists?[0].url)
		XCTAssertNil(artistAlbums[0].artists?[0].picture)
		XCTAssertNil(artistAlbums[0].artists?[0].popularity)
		XCTAssertEqual(artistAlbums[0].artists?[0].type, "MAIN")
		
		XCTAssertEqual(artistAlbums[0].artists?[1].id, 4631340)
		XCTAssertEqual(artistAlbums[0].artists?[1].name, "Metropole Orkest")
		XCTAssertNil(artistAlbums[0].artists?[1].url)
		XCTAssertNil(artistAlbums[0].artists?[1].picture)
		XCTAssertNil(artistAlbums[0].artists?[1].popularity)
		XCTAssertEqual(artistAlbums[0].artists?[1].type, "MAIN")
		
		XCTAssertEqual(artistAlbums[0].artists?[2].id, 4374293)
		XCTAssertEqual(artistAlbums[0].artists?[2].name, "Jules Buckley")
		XCTAssertNil(artistAlbums[0].artists?[2].url)
		XCTAssertNil(artistAlbums[0].artists?[2].picture)
		XCTAssertNil(artistAlbums[0].artists?[2].popularity)
		XCTAssertEqual(artistAlbums[0].artists?[2].type, "MAIN")
		
		XCTAssertEqual(artistAlbums[1].id, 100006800)
		XCTAssertEqual(artistAlbums[1].title, "Djesse (Vol. 1)")
		XCTAssertEqual(artistAlbums[1].audioQuality, .hifi)
	}

	func testGetArtistTopTracks() {
		// Probably needs to be updated once in a while as it can change
		
		let optionalArtistTopTracks = session.getArtistTopTracks(artistId: 16579)
		XCTAssertNotNil(optionalArtistTopTracks)
		guard let artistTopTracks = optionalArtistTopTracks else {
			return
		}
		
		XCTAssertEqual(artistTopTracks.count, 157)
		
		XCTAssertEqual(artistTopTracks[0].id, 8414613)
		XCTAssertEqual(artistTopTracks[0].title, "In diesem Moment")
		XCTAssertEqual(artistTopTracks[0].duration, 226)
		XCTAssertEqual(artistTopTracks[0].replayGain, -9.8)
		XCTAssertEqual(artistTopTracks[0].peak, 0.980865)
		XCTAssertEqual(artistTopTracks[0].allowStreaming, true)
		XCTAssertEqual(artistTopTracks[0].streamReady, true)
		XCTAssertEqual(artistTopTracks[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-06-05"))
		XCTAssertEqual(artistTopTracks[0].trackNumber, 4)
		XCTAssertEqual(artistTopTracks[0].volumeNumber, 1)
		//		print(artistTopTracks[0].popularity)
		XCTAssertEqual(artistTopTracks[0].copyright,
					   "2011 Starwatch Music Under Exclusive License To Warner Music Group Germany Holding GmbH / A Warner Music Group Company")
		XCTAssertEqual(artistTopTracks[0].url,
					   URL(string: "http://www.tidal.com/track/8414613"))
		XCTAssertEqual(artistTopTracks[0].isrc, "DEA621100465")
		XCTAssertEqual(artistTopTracks[0].editable, false)
		XCTAssertEqual(artistTopTracks[0].explicit, false)
		XCTAssertEqual(artistTopTracks[0].audioQuality, .hifi)
		
		// Artists
		XCTAssertEqual(artistTopTracks[0].artists.count, 1)
		XCTAssertEqual(artistTopTracks[0].artists[0].id, 16579)
		XCTAssertEqual(artistTopTracks[0].artists[0].name, "Roger Cicero")
		XCTAssertEqual(artistTopTracks[0].artists[0].type, "MAIN")
		
		// Album
		XCTAssertEqual(artistTopTracks[0].album.id, 8414609)
		XCTAssertEqual(artistTopTracks[0].album.title, "In diesem Moment")
		
		// More Tracks
		XCTAssertEqual(artistTopTracks[1].id, 17690644)
		XCTAssertEqual(artistTopTracks[1].title, "Wir sind da (Giraffenaffensong)")
		XCTAssertEqual(artistTopTracks[2].id, 17690654)
		XCTAssertEqual(artistTopTracks[2].title, "Die Affen rasen durch den Wald")
	}

	func testGetArtistBio() {
		// Probably needs to be updated once in a while as it can change
		let artistBio = session.getArtistBio(artistId: 16579)
		
		XCTAssertEqual(artistBio?.source, "TiVo")
//		print(DateFormatter.iso8601OptionalTime.string(for: artistBio?.lastUpdated))
		XCTAssertEqual(artistBio?.lastUpdated,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2019-03-09T19:22:46.937GMT"))
		// Bio is not consistent, therefore cannot be tested properly.
		// Sometimes some of the referenced artists or albums have a so-called wimpLink, sometimes exactly the same references don't have a wimpLink.
//		XCTAssertEqual(artistBio?.text, "")
	}

	func testGetArtistSimilar() {
		let optionalSimilarArtists = session.getArtistSimilar(artistId: 7553669)
		XCTAssertNotNil(optionalSimilarArtists)
		guard let similarArtists = optionalSimilarArtists else {
			return
		}
		
		XCTAssertEqual(similarArtists.count, 7)
		
		// Not necessarely in the same order as on website
		XCTAssertEqual(similarArtists[0].id, 10695)
		XCTAssertEqual(similarArtists[0].name, "Jamie Cullum")
		XCTAssertEqual(similarArtists[0].url, URL(string:
			"http://www.tidal.com/artist/10695"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(similarArtists[0].picture,
					   "bcb0f0ce-3473-4140-af59-bdcce400a795")
		XCTAssertNotNil(similarArtists[0].popularity)
		XCTAssertNil(similarArtists[0].type)
		XCTAssertNil(similarArtists[0].banner)
		XCTAssertEqual(similarArtists[0].relationType, "SIMILAR_ARTIST")
		
		XCTAssertEqual(similarArtists[1].id, 3513667)
		XCTAssertEqual(similarArtists[1].name, "Holly Cole")
	}

	func testGetArtistRadio() {
		// Probably needs to be updated once in a while as it can change
		
		let optionalArtistRadio = session.getArtistRadio(artistId: 16579)
		XCTAssertNotNil(optionalArtistRadio)
		guard let artistRadio = optionalArtistRadio else {
			return
		}
		
		XCTAssertEqual(artistRadio.count, 100)
		
		XCTAssertEqual(artistRadio[0].id, 8414613)
		XCTAssertEqual(artistRadio[0].title, "In diesem Moment")
		XCTAssertEqual(artistRadio[0].duration, 226)
		XCTAssertEqual(artistRadio[0].replayGain, -9.8)
		XCTAssertEqual(artistRadio[0].peak, 0.980865)
		XCTAssertEqual(artistRadio[0].allowStreaming, true)
		XCTAssertEqual(artistRadio[0].streamReady, true)
		XCTAssertEqual(artistRadio[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-06-05"))
		XCTAssertEqual(artistRadio[0].trackNumber, 4)
		XCTAssertEqual(artistRadio[0].volumeNumber, 1)
		//		print(artistTopTracks[0].popularity)
		XCTAssertEqual(artistRadio[0].copyright,
					   "2011 Starwatch Music Under Exclusive License To Warner Music Group Germany Holding GmbH / A Warner Music Group Company")
		XCTAssertEqual(artistRadio[0].url,
					   URL(string: "http://www.tidal.com/track/8414613"))
		XCTAssertEqual(artistRadio[0].isrc, "DEA621100465")
		XCTAssertEqual(artistRadio[0].editable, false)
		XCTAssertEqual(artistRadio[0].explicit, false)
		XCTAssertEqual(artistRadio[0].audioQuality, .hifi)
		
		// Artists
		XCTAssertEqual(artistRadio[0].artists.count, 1)
		XCTAssertEqual(artistRadio[0].artists[0].id, 16579)
		XCTAssertEqual(artistRadio[0].artists[0].name, "Roger Cicero")
		XCTAssertEqual(artistRadio[0].artists[0].type, "MAIN")
		
		// Album
		XCTAssertEqual(artistRadio[0].album.id, 8414609)
		XCTAssertEqual(artistRadio[0].album.title, "In diesem Moment")
		
		// More Tracks
		// Impossible to write consistent tests as the tracks are constantly changing
//		XCTAssertEqual(artistRadio[1].id, 58965655)
//		XCTAssertEqual(artistRadio[1].title, "Du erinnerst mich an Liebe")
//		XCTAssertEqual(artistRadio[1].artists[0].id, 3673052)
//		XCTAssertEqual(artistRadio[1].artists[0].name, "Ich + Ich")
//		XCTAssertEqual(artistRadio[2].id, 36309894)
//		XCTAssertEqual(artistRadio[2].title, "Symphonie (On Stage)")
//		XCTAssertEqual(artistRadio[2].artists[0].id, 2771)
//		XCTAssertEqual(artistRadio[2].artists[0].name, "Silbermond")
	}
	
	func testTrackRadio() {
		let optionalTrackRadio = session.getTrackRadio(trackId: 59978883)
		XCTAssertNotNil(optionalTrackRadio)
		guard let trackRadio = optionalTrackRadio else {
			return
		}
		
		XCTAssertEqual(trackRadio[0].id, 59978883)
		XCTAssertEqual(trackRadio[0].title, "In My Room")
	}
	
	func testGetUser() {
		XCTAssertNotNil(session.userId)
		guard let userId = session.userId else {
			return
		}
		let user = session.getUser(userId: userId)
		// For privacy reasons only testing userId of current logged in user
		XCTAssertEqual(user?.id, userId)
//		print(user?.username as Any)
//		print(user?.firstName as Any)
//		print(user?.lastName as Any)
//		print(user?.email as Any)
//		print(user?.countryCode as Any)
//		print(user?.created as Any)
//		print(user?.picture as Any)
//		print(user?.newsletter as Any)
//		print(user?.acceptedEULA as Any)
//		print(user?.gender as Any)
//		print(user?.dateOfBirth as Any)
//		print(user?.facebookUid as Any)
	}
	
	func testGetUserPlaylists() {
		XCTAssertNotNil(session.userId)
		guard let userId = session.userId else {
			return
		}
		let optionalPlaylists = session.getUserPlaylists(userId: userId)
		XCTAssertNotNil(optionalPlaylists)
		guard let playlists = optionalPlaylists else {
			return
		}
		
		// Hard to test as different for every user
		// Needs to be changed by tester
		XCTAssertEqual(playlists[16].uuid, "825a0e70-c918-40b8-89c6-247dfbac04b4")
		// Testing the handling of "" in Strings & JSON
		XCTAssertEqual(playlists[16].title, #"Schlechte "Musik""#)
		XCTAssertEqual(playlists[16].type, .user)
		XCTAssertEqual(playlists[16].creator.id, userId)
		XCTAssertNil(playlists[16].creator.name)
		XCTAssertNil(playlists[16].creator.url)
		XCTAssertNil(playlists[16].creator.picture)
		XCTAssertNil(playlists[16].creator.popularity)
	}
	
	func testGetMixes() {
		// No general test as mixes are different for every user
		
		let optionalMixse = session.getMixes()
		XCTAssertNotNil(optionalMixse)
		guard let mixes = optionalMixse else {
			return
		}
		
		XCTAssertEqual(mixes.count, 6)
	}
	
	func testGetMixPlaylistTracks() {
		// Have to get a new list of mixes for each user and time
		let optionalMixse = session.getMixes()
		XCTAssertNotNil(optionalMixse)
		guard let mixes = optionalMixse else {
			return
		}
		let mixId = mixes[0].id
		let optionalTracks = session.getMixPlaylistTracks(mixId: mixId)
		XCTAssertNotNil(optionalTracks)
		guard let tracks = optionalTracks else {
			return
		}
		
		XCTAssertEqual(tracks.count, 40)
	}
	
	func testGetMoods() {
		let optionalMoods = session.getMoods()
		XCTAssertNotNil(optionalMoods)
		guard let moods = optionalMoods else {
			return
		}
		
		XCTAssertEqual(moods[0].name, "Relax")
		XCTAssertEqual(moods[0].path, "relax")
		XCTAssertEqual(moods[0].hasPlaylists, true)
		XCTAssertEqual(moods[0].hasArtists, false)
		XCTAssertEqual(moods[0].hasAlbums, false)
		XCTAssertEqual(moods[0].hasTracks, false)
		XCTAssertEqual(moods[0].hasVideos, false)
		XCTAssertEqual(moods[0].image, "b589ddb1-ef3a-457e-9e00-84b475196ee2")
		
		XCTAssertEqual(moods[1].name, "Party")
		XCTAssertEqual(moods[1].path, "party")
	}
	
	func testGetMoodPlaylist() {
		// Hard to test because contents will change fairly often
		let optionalPlaylists = session.getMoodPlaylists(moodPath: "relax")
		XCTAssertNotNil(optionalPlaylists)
		guard let playlists = optionalPlaylists else {
			return
		}
		
		// Hard to test as different for every user
		// Needs to be changed by tester
		XCTAssertEqual(playlists[0].uuid, "98676f10-0aa1-4c8c-ba84-4f84e370f3d2")
		// Testing the handling of "" in Strings & JSON
		XCTAssertEqual(playlists[0].title, "Breathe In, Breathe Out")
//		XCTAssertEqual(playlists[0].numberOfTracks, 64)
		XCTAssertEqual(playlists[0].numberOfVideos, 0)
		XCTAssertEqual(playlists[0].description,
					   "Step onto your mat and into your zen with these meditative tracks.")
//		XCTAssertEqual(playlists[0].duration, 18592)
		XCTAssertEqual(playlists[0].created,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-02-05T21:44:05.000GMT"))
		XCTAssertEqual(playlists[0].publicPlaylist, false)
		XCTAssertEqual(playlists[0].url, URL(string:
			"http://www.tidal.com/playlist/98676f10-0aa1-4c8c-ba84-4f84e370f3d2"))
		XCTAssertEqual(playlists[0].image, "b129e3dc-33c0-4b5a-b99b-9672d140c5a7")
		XCTAssertEqual(playlists[0].squareImage, "bd101b96-2354-4dc4-b868-31a356e4679a")
		XCTAssertEqual(playlists[0].type, .editorial)
		XCTAssertEqual(playlists[0].creator.id, 0)
	}
	
	func testGetGenres() { // Overview over all Genres
		let optionalGenres = session.getGenres()
		XCTAssertNotNil(optionalGenres)
		guard let genres = optionalGenres else {
			return
		}
		
		XCTAssertEqual(genres[1].name, "Pop")
		XCTAssertEqual(genres[1].path, "Pop")
		XCTAssertEqual(genres[1].hasPlaylists, true)
		XCTAssertEqual(genres[1].hasArtists, false)
		XCTAssertEqual(genres[1].hasAlbums, true)
		XCTAssertEqual(genres[1].hasTracks, true)
		XCTAssertEqual(genres[1].hasVideos, true)
		XCTAssertEqual(genres[1].image, "0239132d-99be-41f4-929d-e27280f7bff1")
		
		XCTAssertEqual(genres[5].name, "R&B / Soul")
		XCTAssertEqual(genres[5].path, "Funk")
	}
	
	func testGetGenreTracks() {
		// Hard to test because contents will change fairly often
		let optionalGenreTracks = session.getGenreTracks(genrePath: "Pop")
		XCTAssertNotNil(optionalGenreTracks)
		guard let genreTracks = optionalGenreTracks else {
			return
		}
		XCTAssertFalse(genreTracks.isEmpty)
	}
	
	func testGetGenreAlbums() {
		// Hard to test because contents will change fairly often
		let optionalGenreAlbums = session.getGenreAlbums(genreName: "Pop")
		XCTAssertNotNil(optionalGenreAlbums)
		guard let genreAlbums = optionalGenreAlbums else {
			return
		}
		XCTAssertFalse(genreAlbums.isEmpty)
	}
	
	func testGetGenrePlaylists() {
		// Hard to test because contents will change fairly often
		let optionalGenrePlaylists = session.getGenrePlaylists(genreName: "Pop")
		XCTAssertNotNil(optionalGenrePlaylists)
		guard let genrePlaylists = optionalGenrePlaylists else {
			return
		}
		XCTAssertFalse(genrePlaylists.isEmpty)
	}
	
	func testGetFeatured() {
		// Hard to test because contents will change fairly often
		let optionalFeatured = session.getFeatured()
		XCTAssertNotNil(optionalFeatured)
		guard let featured = optionalFeatured else {
			return
		}
		XCTAssertFalse(featured.isEmpty)
	}
	
	func testDateDecoder() {
		// Tests if the DateDecoder defined at the bottom of Codable correctly decodes a date.
		// Makes sure there is no time zone switching.
		let rawString = "2016-07-15"
		let date = DateFormatter.iso8601OptionalTime.date(from: rawString)!
		let resultString = "2016-07-15 00:00:00 +0000"
		XCTAssertEqual(resultString, "\(date)")
		
		// Test sub-second accuracy
		let subSecondString = "2019-03-28T06:49:21.123GMT"
		let subSecondDate = DateFormatter.iso8601OptionalTime.date(from: subSecondString)!
		let wrongResult = "2019-03-28T06:49:21.000GMT"
		let subSecondResult = DateFormatter.iso8601OptionalTime.string(from: subSecondDate)
		XCTAssertNotEqual(wrongResult, subSecondResult)
		XCTAssertEqual(subSecondString, subSecondResult)
	}

}
