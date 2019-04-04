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
	
	var session: Session = Session(config: Config(quality: .LOSSLESS, loginInformation: readDemoLoginInformation()))
	
	var tempConfig: Config?
	var tempSession: Session?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Before messing with UserDefaults, load Session with saved values into variable
		tempSession = Session(config: nil)
		tempSession?.loadSession()
		
		// Now, we are free to mess around
		let config = Config(quality: .LOSSLESS, loginInformation: readDemoLoginInformation())
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
	
//	func testLogin() {
//		let loginInfo = readDemoLoginInformation()
//		let config = Config(quality: .LOSSLESS, loginInformation: loginInfo)
//		session = Session(config: config)
//		let result = session.login()
//		XCTAssert(result)
//	}
//
//	func testWrongLogin() {
//		// Wrong Login Info
//		let loginInfo1 = LoginInformation(username: "ABC", password: "ABC")
//		let config1 = Config(quality: .LOSSLESS, loginInformation: loginInfo1)
//		session = Session(config: config1)
//		let result1 = session.login()
//		XCTAssertFalse(result1)
//
//		// Empty Login Info
//		let loginInfo2 = LoginInformation(username: "", password: "")
//		let config2 = Config(quality: .LOSSLESS, loginInformation: loginInfo2)
//		session = Session(config: config2)
//		let result2 = session.login()
//		XCTAssertFalse(result2)
//	}
	
	func testCheckLogin() {
		XCTAssert(session.checkLogin())
		
		let config = Config(quality: .LOSSLESS, loginInformation: readDemoLoginInformation())
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
		XCTAssertEqual(info?.highestSoundQuality, "LOSSLESS")
		XCTAssertEqual(info?.premiumAccess, true)
		XCTAssertEqual(info?.canGetTrial, false)
		XCTAssertEqual(info?.paymentType, "PARENT")
	}
	
	func testGetMediaUrl() {
		let url = session.getMediaUrl(trackId: 59978883)
		XCTAssertNotNil(url)
	}
	
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
	}
	
	func testSearchAlbum() {
		// TODO: Change "In my Room" to "Djesse" to test multiple artists
		let searchResult = session.search(for: "Jacob Collier In My Room")
		XCTAssertEqual(searchResult?.albums.totalNumberOfItems, 1)
		XCTAssertEqual(searchResult?.albums.items[0].id, 59978881)
		XCTAssertEqual(searchResult?.albums.items[0].title, "In My Room")
		XCTAssertEqual(searchResult?.albums.items[0].duration, 3531)
		XCTAssertEqual(searchResult?.albums.items[0].streamReady, true)
		XCTAssertEqual(searchResult?.albums.items[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-01"))
		XCTAssertEqual(searchResult?.albums.items[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfTracks, 11)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfVideos, 0)
		XCTAssertEqual(searchResult?.albums.items[0].numberOfVolumes, 1)
		XCTAssertEqual(searchResult?.albums.items[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-15"))
		XCTAssertEqual(searchResult?.albums.items[0].copyright, "2016 Membran")
		XCTAssertNotNil(searchResult?.albums.items[0].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].audioQuality, "LOSSLESS")
		
		// Album Artist
		XCTAssertEqual(searchResult?.albums.items[0].artists?.count, 1)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].id, 7553669)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].name, "Jacob Collier")
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].url)
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].picture)
		XCTAssertNil(searchResult?.albums.items[0].artists?[0].popularity)
		XCTAssertEqual(searchResult?.albums.items[0].artists?[0].type, "MAIN")
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
						"2019-02-28T21:14:54.402GMT"))
		XCTAssertEqual(searchResult?.playlists.items[0].created,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-01-19T17:56:03.125GMT"))
		XCTAssertEqual(searchResult?.playlists.items[0].type, "EDITORIAL")
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
		XCTAssertEqual(searchResult?.tracks.items[0].audioQuality, "LOSSLESS")
		
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
	
	func testTrackRadio() {
		// TODO:
	}
	
	func testGenres() { // Overview over all Genres
		let optionalGenres = session.getGenres()
		XCTAssertNotNil(optionalGenres)
		let genres = optionalGenres!
		
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
