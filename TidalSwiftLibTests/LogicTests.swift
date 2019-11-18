//
//  TidalSwiftTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 21.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class LogicTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	
	var tempConfig: Config?
	var tempSession: Session?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Before messing with UserDefaults, load Session with saved values into variable
		tempSession = Session(config: nil)
		tempSession?.loadSession()
		
		// Now, we are free to mess around
		session = Session(config: nil) // Config is loaded from persistent storage
		
		session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		
		// Delete messed-with UserDefaults
		session.deletePersistentInformation()
		
		// Save back old UserDefaults
		tempSession?.saveConfig()
		tempSession?.saveSession()
    }
	
	// MARK: - Session
	
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
		XCTAssertEqual(oldConfig.imageLocation, session.config.imageLocation)
		XCTAssertEqual(oldConfig.imageSize, session.config.imageSize)
	}
	
	// Login Testing commented out to prevent potential ban from the server if done too often
	func testLogin() {
		let loginInfo = readDemoLoginCredentials()
		let config = Config(quality: .hifi, loginCredentials: loginInfo)
		session = Session(config: config)
		let result = session.login()
		XCTAssert(result)
	}

	// Login Testing commented out to prevent potential ban from the server if done too often
	func testWrongLogin() {
		// Wrong Login Info
		let loginInfo1 = LoginCredentials(username: "ABC", password: "ABC")
		let config1 = Config(quality: .hifi, loginCredentials: loginInfo1)
		session = Session(config: config1)
		let result1 = session.login()
		XCTAssertFalse(result1)

		// Empty Login Info
		let loginInfo2 = LoginCredentials(username: "", password: "")
		let config2 = Config(quality: .hifi, loginCredentials: loginInfo2)
		session = Session(config: config2)
		let result2 = session.login()
		XCTAssertFalse(result2)
	}
	
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
		
		// Values are highly dependent on one's subscription type.
		// Values here are for an account inside a HIFI Family plan.
		XCTAssertEqual(info?.status, "ACTIVE")
		XCTAssertEqual(info?.subscription.type, "HIFI")
		XCTAssertEqual(info?.subscription.offlineGracePeriod, 30)
		XCTAssertEqual(info?.highestSoundQuality, .hifi) // "LOSSLESS" although Master is possible
		XCTAssertEqual(info?.premiumAccess, true)
		XCTAssertEqual(info?.canGetTrial, false)
		XCTAssertEqual(info?.paymentType, "PARENT")
	}
	
	func testGetMediaUrl() {
		let optionalTrackUrl = session.getAudioUrl(trackId: 59978883)
		XCTAssertNotNil(optionalTrackUrl)
		guard let trackUrl = optionalTrackUrl else {
			return
		}
//		print(trackUrl)
		XCTAssert(trackUrl.absoluteString.contains(".m4a"))
		
		let optionalTrackUrl2 = session.getAudioUrl(trackId: 59978883)
		XCTAssertNotNil(optionalTrackUrl2)
		guard let trackUrl2 = optionalTrackUrl2 else {
			return
		}
//		print(trackUrl2)
		XCTAssert(trackUrl2.absoluteString.contains(".m4a"))
	}
	
	// Stops playback if you're listening in the web player or official app
	func testGetVideoUrl() {
		let optionalVideoUrl = session.getVideoUrl(videoId: 98785108)
		XCTAssertNotNil(optionalVideoUrl)
		guard let videoUrl = optionalVideoUrl else {
			return
		}
//		print(videoUrl)
		XCTAssert(videoUrl.absoluteString.contains(".m3u8"))
		
		let optionalVideoUrl2 = session.getVideoUrl(videoId: 98785108)
		XCTAssertNotNil(optionalVideoUrl2)
		guard let videoUrl2 = optionalVideoUrl2 else {
			return
		}
//		print(videoUrl2)
		XCTAssert(videoUrl2.absoluteString.contains(".m3u8"))
	}
	
	func testGetImageUrl() {
		// General (Album)
		let url = session.getImageUrl(imageId: "e60d7380-2a14-4011-bbc1-a3a1f0c576d6", resolution: 1280)
		XCTAssertEqual(url, URL(string:
			"https://resources.tidal.com/images/e60d7380/2a14/4011/bbc1/a3a1f0c576d6/1280x1280.jpg"))
		
		// General non-square (FeaturedItem)
		let urlNonSquare = session.getImageUrl(imageId: "a133cb38-6ae7-44b7-9fc5-f6a9b48ee3bc",
											   resolution: 1100, resolutionY: 800)
		XCTAssertEqual(urlNonSquare, URL(string:
			"https://resources.tidal.com/images/a133cb38/6ae7/44b7/9fc5/f6a9b48ee3bc/1100x800.jpg"))
		
		// Album
		let album = session.getAlbum(albumId: 100006868)
		let albumUrl = album?.getCoverUrl(session: session, resolution: 1280)
		XCTAssertEqual(albumUrl, URL(string:
			"https://resources.tidal.com/images/e60d7380/2a14/4011/bbc1/a3a1f0c576d6/1280x1280.jpg"))
		
		// Artist
		let artist = session.getArtist(artistId: 16579)
		let artistUrl = artist?.getPictureUrl(session: session, resolution: 750)
		XCTAssertEqual(artistUrl, URL(string:
			"https://resources.tidal.com/images/2fb1902b/7216/407b/b674/5edb93d00a84/750x750.jpg"))
		
		// Track (Album Cover)
		let track = session.getTrack(trackId: 59978883)
		let trackUrl = track?.getCoverUrl(session: session, resolution: 1280)
		XCTAssertEqual(trackUrl, URL(string:
			"https://resources.tidal.com/images/5439beb7/36f0/480e/bc58/99515af8709d/1280x1280.jpg"))
		
		// Video
		let video = session.getVideo(videoId: 98785108)
		let videoUrl = video?.getImageUrl(session: session, resolution: 750)
		XCTAssertEqual(videoUrl, URL(string:
			"https://resources.tidal.com/images/94cf59fb/2816/4c40/989d/8aff2365baf9/750x750.jpg"))
		
		// Playlist
		let playlist = session.getPlaylist(playlistId: "a784a00e-8f76-4a67-8624-656a1e80f7ed")
		let playlistUrl = playlist?.getImageUrl(session: session, resolution: 750)
		XCTAssertEqual(playlistUrl, URL(string:
			"https://resources.tidal.com/images/4faed9dd/8f52/4379/a4ce/a73e9cc07d33/750x750.jpg"))
		// Changes periodically
		
		// Genres & Moods have image ID, but I can't find a fitting resolution to access it
		
		// FeaturedItem
		// Not consistent, therefore hard to test
		
		// Mix
		// Not consistent, therefore hard to test
	}
	
	// MARK: - Search
	
	func testSearchArtist() {
		let searchResult = session.search(for: "Roger Cicero")
		XCTAssertEqual(searchResult?.artists.count, 2)
		XCTAssertEqual(searchResult?.artists[0].id, 16579)
		XCTAssertEqual(searchResult?.artists[0].name, "Roger Cicero")
		XCTAssertEqual(searchResult?.artists[0].url,
					   URL(string: "http://www.tidal.com/artist/16579"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(searchResult?.artists[0].picture,
					   "2fb1902b-7216-407b-b674-5edb93d00a84")
		XCTAssertNotNil(searchResult?.artists[0].popularity)
		XCTAssertNil(searchResult?.artists[0].type)
		XCTAssertNil(searchResult?.artists[0].banner)
		XCTAssertNil(searchResult?.artists[0].relationType)
	}
	
	func testSearchAlbum() {
		let searchResult = session.search(for: "Jacob Collier Djesse Vol. 1")
		XCTAssertEqual(searchResult?.albums.count, 2)
		
		// Master Version
		XCTAssertEqual(searchResult?.albums[0].id, 100006868)
		XCTAssertEqual(searchResult?.albums[0].title, "Djesse Vol. 1")
		XCTAssertEqual(searchResult?.albums[0].duration, 3196)
		XCTAssertEqual(searchResult?.albums[0].streamReady, true)
		XCTAssertEqual(searchResult?.albums[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(searchResult?.albums[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.albums[0].premiumStreamingOnly, false)
		XCTAssertEqual(searchResult?.albums[0].numberOfTracks, 9)
		XCTAssertEqual(searchResult?.albums[0].numberOfVideos, 0)
		XCTAssertEqual(searchResult?.albums[0].numberOfVolumes, 1)
		XCTAssertEqual(searchResult?.albums[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(searchResult?.albums[0].copyright,
					   "© 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertEqual(searchResult?.albums[0].type, "ALBUM")
		XCTAssertEqual(searchResult?.albums[0].url,
					   URL(string: "http://www.tidal.com/album/100006868"))
		XCTAssertEqual(searchResult?.albums[0].cover,
					   "e60d7380-2a14-4011-bbc1-a3a1f0c576d6")
		XCTAssertNil(searchResult?.albums[0].videoCover)
		XCTAssertEqual(searchResult?.albums[0].explicit, false)
		XCTAssertEqual(searchResult?.albums[0].upc, "00602577265037")
		
		XCTAssertNotNil(searchResult?.albums[0].popularity)
		XCTAssertEqual(searchResult?.albums[0].audioQuality, .master) // Master Version
		XCTAssertEqual(searchResult?.albums[0].audioModes, [.stereo])
		
		// HiFi Version
		XCTAssertEqual(searchResult?.albums[1].audioQuality, .hifi)
		
		// Album Artist
		XCTAssertNil(searchResult?.albums[0].artist)
		
		// Album Artists
		XCTAssertEqual(searchResult?.albums[0].artists?.count, 3)
		XCTAssertEqual(searchResult?.albums[0].artists?[0].id, 7553669)
		XCTAssertEqual(searchResult?.albums[0].artists?[0].name, "Jacob Collier")
		XCTAssertNil(searchResult?.albums[0].artists?[0].url)
		XCTAssertNil(searchResult?.albums[0].artists?[0].picture)
		XCTAssertNil(searchResult?.albums[0].artists?[0].popularity)
		XCTAssertEqual(searchResult?.albums[0].artists?[0].type, "MAIN")
		
		XCTAssertEqual(searchResult?.albums[0].artists?[1].id, 4631340)
		XCTAssertEqual(searchResult?.albums[0].artists?[1].name, "Metropole Orkest")
		XCTAssertNil(searchResult?.albums[0].artists?[1].url)
		XCTAssertNil(searchResult?.albums[0].artists?[1].picture)
		XCTAssertNil(searchResult?.albums[0].artists?[1].popularity)
		XCTAssertEqual(searchResult?.albums[0].artists?[1].type, "MAIN")
		
		XCTAssertEqual(searchResult?.albums[0].artists?[2].id, 4374293)
		XCTAssertEqual(searchResult?.albums[0].artists?[2].name, "Jules Buckley")
		XCTAssertNil(searchResult?.albums[0].artists?[2].url)
		XCTAssertNil(searchResult?.albums[0].artists?[2].picture)
		XCTAssertNil(searchResult?.albums[0].artists?[2].popularity)
		XCTAssertEqual(searchResult?.albums[0].artists?[2].type, "MAIN")
	}
	
	func testSearchPlaylist() {
		let searchResult = session.search(for: "Barack Obama Speeches")
		XCTAssertEqual(searchResult?.playlists.count, 1)
		XCTAssertEqual(searchResult?.playlists[0].uuid,
					   "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		XCTAssertEqual(searchResult?.playlists[0].title, "Barack Obama Speeches")
		XCTAssertEqual(searchResult?.playlists[0].numberOfTracks, 19)
		XCTAssertEqual(searchResult?.playlists[0].numberOfVideos, 0)
		let description = "Grab inspiration from this collection of No. 44's notable speeches. "
		XCTAssertEqual(searchResult?.playlists[0].description, description)
		XCTAssertEqual(searchResult?.playlists[0].duration, 34170)
		XCTAssertEqual(searchResult?.playlists[0].lastUpdated,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2019-02-28T21:14:54.000GMT"))
		XCTAssertEqual(searchResult?.playlists[0].created,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-01-19T17:56:03.000GMT"))
		XCTAssertEqual(searchResult?.playlists[0].type, .editorial)
		// Here it's false, but in the Playlist test it's true. No idea, why.
		XCTAssertEqual(searchResult?.playlists[0].publicPlaylist, true)
		XCTAssertEqual(searchResult?.playlists[0].url, URL(string:
			"http://www.tidal.com/playlist/96696a2c-b284-4dd3-8e51-5e0dae44ace0"))
		XCTAssertEqual(searchResult?.playlists[0].image,
					   "43f8e4db-769c-40f6-b561-99609aef0c13")
//		print(searchResult?.playlists[0].popularity)
		XCTAssertEqual(searchResult?.playlists[0].squareImage,
					   "50fbe933-0049-4e0e-be82-2de70b19168e")
	}
	
	func testSearchTrack() {
		let searchResult = session.search(for: "Jacob Collier In My Room")
		XCTAssertEqual(searchResult?.tracks.count, 1)
		XCTAssertEqual(searchResult?.tracks[0].id, 59978883)
		XCTAssertEqual(searchResult?.tracks[0].title, "In My Room")
		XCTAssertEqual(searchResult?.tracks[0].duration, 289)
		XCTAssertEqual(searchResult?.tracks[0].replayGain, -7.04)
		XCTAssertEqual(searchResult?.tracks[0].peak, 0.944366)
		XCTAssertEqual(searchResult?.tracks[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.tracks[0].streamReady, true)
		XCTAssertEqual(searchResult?.tracks[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-01"))
		XCTAssertEqual(searchResult?.tracks[0].trackNumber, 2)
		XCTAssertEqual(searchResult?.tracks[0].volumeNumber, 1)
//		print(searchResult?.tracks[0].popularity)
		XCTAssertEqual(searchResult?.tracks[0].copyright, "(P) 2016 Membran")
		XCTAssertEqual(searchResult?.tracks[0].url,
					   URL(string: "http://www.tidal.com/track/59978883"))
		XCTAssertEqual(searchResult?.tracks[0].isrc, "US23A1500084")
		XCTAssertEqual(searchResult?.tracks[0].editable, false)
		XCTAssertEqual(searchResult?.tracks[0].explicit, false)
		XCTAssertEqual(searchResult?.tracks[0].audioQuality, .hifi)
		XCTAssertEqual(searchResult?.tracks[0].audioModes, [.stereo])
		
		// Artists
		XCTAssertEqual(searchResult?.tracks[0].artists.count, 1)
		XCTAssertEqual(searchResult?.tracks[0].artists[0].id, 7553669)
		XCTAssertEqual(searchResult?.tracks[0].artists[0].name, "Jacob Collier")
//		print(searchResult?.videos[0].artists[0].type) // For no reason "Index out of range"
//		XCTAssertEqual(searchResult?.videos[0].artists[0].type, "MAIN")
		
		// Album
		XCTAssertEqual(searchResult?.tracks[0].album.id, 59978881)
		XCTAssertEqual(searchResult?.tracks[0].album.title, "In My Room")
	}
	
	func testSearchVideo() {
		let searchResult = session.search(for:
			"Jacob Collier With The Love In My Heart")
		XCTAssertEqual(searchResult?.videos.count, 1)
		XCTAssertEqual(searchResult?.videos[0].id, 98785108)
		XCTAssertEqual(searchResult?.videos[0].title,
					   "With The Love In My Heart")
		XCTAssertEqual(searchResult?.videos[0].volumeNumber, 1)
		XCTAssertEqual(searchResult?.videos[0].trackNumber, 1)
		XCTAssertEqual(searchResult?.videos[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-11-16"))
		XCTAssertNil(searchResult?.videos[0].imagePath)
		XCTAssertEqual(searchResult?.videos[0].imageId,
					   "94cf59fb-2816-4c40-989d-8aff2365baf9")
		XCTAssertEqual(searchResult?.videos[0].duration, 406)
		XCTAssertEqual(searchResult?.videos[0].quality, "MP4_1080P")
		XCTAssertEqual(searchResult?.videos[0].streamReady, true)
		XCTAssertEqual(searchResult?.videos[0].streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-11-16T18:00:00.000GMT"))
		XCTAssertEqual(searchResult?.videos[0].allowStreaming, true)
		XCTAssertEqual(searchResult?.videos[0].explicit, false)
//		print(searchResult?.videos[0].popularity)
		XCTAssertEqual(searchResult?.videos[0].type, "Music Video")
		XCTAssertNil(searchResult?.videos[0].adsUrl)
		XCTAssertEqual(searchResult?.videos[0].adsPrePaywallOnly, true)
		
		// Artists
		XCTAssertEqual(searchResult?.tracks[0].artists.count, 3)
		
		XCTAssertEqual(searchResult?.tracks[0].artists[0].id, 7553669)
		XCTAssertEqual(searchResult?.tracks[0].artists[0].name, "Jacob Collier")
		XCTAssertEqual(searchResult?.videos[0].artists[0].type, "MAIN")
		
		XCTAssertEqual(searchResult?.tracks[0].artists[1].id, 4631340)
		XCTAssertEqual(searchResult?.tracks[0].artists[1].name, "Metropole Orkest")
		XCTAssertEqual(searchResult?.videos[0].artists[1].type, "MAIN")
		
		XCTAssertEqual(searchResult?.tracks[0].artists[2].id, 4374293)
		XCTAssertEqual(searchResult?.tracks[0].artists[2].name, "Jules Buckley")
		XCTAssertEqual(searchResult?.videos[0].artists[2].type, "MAIN")
		
		// Album (probably need to find a better example)
//		XCTAssertNil(searchResult?.videos[0].album)
		
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
//		XCTAssertEqual(searchResult?.tracks.totalNumberOfItems, 300)
//		XCTAssertEqual(searchResult?.tracks.limit, 50)
//		XCTAssertEqual(searchResult?.tracks.items.count, 50)
//		XCTAssertEqual(searchResult?.tracks.offset, 0)
		XCTAssertEqual(searchResult?.tracks.count, 50)
		
		// Test Offset
		let searchResultWithOffset = session.search(for: "Rolf Zuckowski", offset: 1)
//		XCTAssertEqual(searchResultWithOffset?.tracks.limit, 50)
//		XCTAssertEqual(searchResultWithOffset?.tracks.offset, 1)
//
//		XCTAssertEqual(searchResultWithOffset?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResultWithOffset?.tracks.count, 50)
		
		// Test Limit
		let searchResultWithLimit = session.search(for: "Rolf Zuckowski", limit: 5)
//		XCTAssertEqual(searchResultWithLimit?.tracks.limit, 5)
//		XCTAssertEqual(searchResultWithLimit?.tracks.offset, 0)
//
//		XCTAssertEqual(searchResultWithLimit?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResultWithLimit?.tracks.count, 5)
		
		// Test Big Offset
		let searchResultWithBigOffset1 = session.search(for: "Rolf Zuckowski", offset: 301)
//		XCTAssertEqual(searchResultWithBigOffset1?.tracks.limit, 50)
//		XCTAssertEqual(searchResultWithBigOffset1?.tracks.offset, 301)
//		XCTAssertEqual(searchResultWithBigOffset1?.tracks.totalNumberOfItems, 300)
//		XCTAssertEqual(searchResultWithBigOffset1?.tracks.items.count, 0)
		XCTAssertEqual(searchResultWithBigOffset1?.tracks.count, 0)
		
		let searchResultWithBigOffset2 = session.search(for: "Rolf Zuckowski", offset: 275)
//		XCTAssertEqual(searchResultWithBigOffset2?.tracks.limit, 50)
//		XCTAssertEqual(searchResultWithBigOffset2?.tracks.offset, 275)
//		XCTAssertEqual(searchResultWithBigOffset2?.tracks.totalNumberOfItems, 300)
//		XCTAssertEqual(searchResultWithBigOffset2?.tracks.items.count, 25)
		XCTAssertEqual(searchResultWithBigOffset2?.tracks.count, 25)
		
		// Test High Limit
		let searchResultWithHighLimit = session.search(for: "Rolf Zuckowski", limit: 500)
//		XCTAssertEqual(searchResultWithHighLimit?.tracks.limit, 500)
//		XCTAssertEqual(searchResultWithHighLimit?.tracks.offset, 0)
//		XCTAssertEqual(searchResultWithHighLimit?.tracks.items.count, 300)
//		XCTAssertEqual(searchResultWithHighLimit?.tracks.totalNumberOfItems, 300)
		XCTAssertEqual(searchResultWithHighLimit?.tracks.count, 300)
	}
	
	// MARK: - Get
	
	func testGetTrack() {
		let optionalTrack = session.getTrack(trackId: 59978883)
		XCTAssertNotNil(optionalTrack)
		guard let track = optionalTrack else {
			return
		}
		
		XCTAssertEqual(track.id, 59978883)
		XCTAssertEqual(track.title, "In My Room")
		XCTAssertEqual(track.duration, 289)
		XCTAssertEqual(track.replayGain, -7.04)
		XCTAssertEqual(track.peak, 0.944366)
		XCTAssertEqual(track.allowStreaming, true)
		XCTAssertEqual(track.streamReady, true)
		XCTAssertEqual(track.streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-01"))
		XCTAssertEqual(track.trackNumber, 2)
		XCTAssertEqual(track.volumeNumber, 1)
		//		print(track.popularity)
		XCTAssertEqual(track.copyright, "(P) 2016 Membran")
		XCTAssertEqual(track.url,
					   URL(string: "http://www.tidal.com/track/59978883"))
		XCTAssertEqual(track.isrc, "US23A1500084")
		XCTAssertEqual(track.editable, false)
		XCTAssertEqual(track.explicit, false)
		XCTAssertEqual(track.audioQuality, .hifi)
		XCTAssertEqual(track.audioModes, [.stereo])
		
		// Artists
		XCTAssertEqual(track.artists.count, 1)
		XCTAssertEqual(track.artists[0].id, 7553669)
		XCTAssertEqual(track.artists[0].name, "Jacob Collier")
		//		print(searchResult?.videos[0].artists[0].type) // For no reason "Index out of range"
		//		XCTAssertEqual(searchResult?.videos[0].artists[0].type, "MAIN")
		
		// Album
		XCTAssertEqual(track.album.id, 59978881)
		XCTAssertEqual(track.album.title, "In My Room")
	}
	
	func testGetTracksCredits() {
		let credits = session.getTrackCredits(trackId: 113133550)
		XCTAssertEqual(credits?.count, 12)
	}
	
	func testCleanTracks() {
		let optionalPlaylistTracks = session.getPlaylistTracks(playlistId: "96696a2c-b284-4dd3-8e51-5e0dae44ace0")
		XCTAssertNotNil(optionalPlaylistTracks)
		guard let playlistTracks = optionalPlaylistTracks else {
			return
		}
		
		XCTAssertEqual(playlistTracks.count, 20)
		
		// For some reason this exact track doesn't exist even though it's technically part of the playlist
		// And for some reason it just gained audioQuality, but not streamStartDate
		XCTAssertEqual(playlistTracks[17].id, 16557722)
		XCTAssertNil(playlistTracks[17].streamStartDate)
//		XCTAssertNil(playlistTracks[17].audioQuality)
		
		let cleanedTrackList = session.cleanTrackList(playlistTracks)
		XCTAssertEqual(cleanedTrackList.count, 19)
	}
	
	func testGetVideo() {
		let optionalVideo = session.getVideo(videoId: 98785108)
		XCTAssertNotNil(optionalVideo)
		guard let video = optionalVideo else {
			return
		}
		
		XCTAssertEqual(video.id, 98785108)
		XCTAssertEqual(video.title, "With The Love In My Heart")
		XCTAssertEqual(video.volumeNumber, 1)
		XCTAssertEqual(video.trackNumber, 1)
		XCTAssertEqual(video.releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-11-16"))
		XCTAssertNil(video.imagePath)
		XCTAssertEqual(video.imageId, "94cf59fb-2816-4c40-989d-8aff2365baf9")
		XCTAssertEqual(video.duration, 406)
		XCTAssertEqual(video.quality, "MP4_1080P")
		XCTAssertEqual(video.streamReady, true)
		XCTAssertEqual(video.streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from:
						"2018-11-16T18:00:00.000GMT"))
		XCTAssertEqual(video.allowStreaming, true)
		XCTAssertEqual(video.explicit, false)
		//		print(video.popularity)
		XCTAssertEqual(video.type, "Music Video")
		XCTAssertNil(video.adsUrl)
		XCTAssertEqual(video.adsPrePaywallOnly, true)
		
		// Artists
		XCTAssertEqual(video.artists.count, 3)
		
		XCTAssertEqual(video.artists[0].id, 7553669)
		XCTAssertEqual(video.artists[0].name, "Jacob Collier")
		XCTAssertEqual(video.artists[0].type, "MAIN")
		
		XCTAssertEqual(video.artists[1].id, 4631340)
		XCTAssertEqual(video.artists[1].name, "Metropole Orkest")
		XCTAssertEqual(video.artists[1].type, "MAIN")
		
		XCTAssertEqual(video.artists[2].id, 4374293)
		XCTAssertEqual(video.artists[2].name, "Jules Buckley")
		XCTAssertEqual(video.artists[2].type, "MAIN")
		
		// Album (probably need to find a better example)
//		XCTAssertNil(video.album)
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
//		print(searchResult?.playlists[0].popularity)
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
		XCTAssertEqual(playlistTracks[0].editable, false)
		XCTAssertEqual(playlistTracks[0].explicit, false)
		XCTAssertEqual(playlistTracks[0].audioQuality, .hifi)
		XCTAssertEqual(playlistTracks[0].audioModes, [.stereo])
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
		XCTAssertEqual(album?.title, "Djesse Vol. 1")
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
		XCTAssertEqual(album?.audioModes, [.stereo])
		
		// Album Artist
		XCTAssertEqual(album?.artist?.id, 7553669)
		XCTAssertEqual(album?.artist?.name, "Jacob Collier")
		XCTAssertNil(album?.artist?.url)
		XCTAssertNil(album?.artist?.picture)
		XCTAssertNil(album?.artist?.popularity)
		XCTAssertEqual(album?.artist?.type, "MAIN")
		
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
		
		
		// Sony 360 Reality Audio Test
		let album360 = session.getAlbum(albumId: 119966103)
		XCTAssertEqual(album360?.audioModes, [.sony360RealityAudio])
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
		XCTAssertEqual(albumTracks[0].audioModes, [.stereo])
		
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
		XCTAssertEqual(albumTracks[0].album.title, "Djesse Vol. 1")
	}
	
	func testIsAlbumCompilation() {
		let optionalAlbumComp = session.getAlbum(albumId: 45143359)
		let optionalAlbumNotComp = session.getAlbum(albumId: 100006868)
		XCTAssertNotNil(optionalAlbumComp)
		XCTAssertNotNil(optionalAlbumNotComp)
		guard let albumComp = optionalAlbumComp,
			  let albumNotComp = optionalAlbumNotComp else {
			return
		}
		
		XCTAssert(albumComp.isCompilation)
		XCTAssertFalse(albumNotComp.isCompilation)
	}
	
	func testGetAlbumCredits() {
		let credits = session.getAlbumCredits(albumId: 100006868)
		XCTAssertEqual(credits?.count, 2)
	}

	func testGetArtist() {
		let artist = session.getArtist(artistId: 16579)
		
		XCTAssertEqual(artist?.id, 16579)
		XCTAssertEqual(artist?.name, "Roger Cicero")
		XCTAssertEqual(artist?.artistTypes, [.artist, .contributor])
		XCTAssertEqual(artist?.url, URL(string:
			"http://www.tidal.com/artist/16579"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(artist?.picture,
					   "2fb1902b-7216-407b-b674-5edb93d00a84")
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
		// Djesse (Vol. 1) exists in two versions, Master and Hifi..
		// It's the second album released and therefore the second and third to last
		let album1 = artistAlbums[artistAlbums.count - 3] // Hifi
		let album2 = artistAlbums[artistAlbums.count - 2] // Master
		
		XCTAssertEqual(album1.id, 100006868)
		XCTAssertEqual(album1.title, "Djesse Vol. 1")
		XCTAssertEqual(album1.duration, 3196)
		XCTAssertEqual(album1.streamReady, true)
		XCTAssertEqual(album1.streamStartDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(album1.allowStreaming, true)
		XCTAssertEqual(album1.numberOfTracks, 9)
		XCTAssertEqual(album1.numberOfVideos, 0)
		XCTAssertEqual(album1.numberOfVolumes, 1)
		XCTAssertEqual(album1.releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-12-07"))
		XCTAssertEqual(album1.copyright,
					   "© 2018 Hajanga Records, under exclusive licence to Geffen Records / Decca, a division of Universal Music Operations Limited")
		XCTAssertNotNil(album1.popularity)
		XCTAssertEqual(album1.audioQuality, .master)
		XCTAssertEqual(album1.audioModes, [.stereo])
		
		// Album Artists
		XCTAssertEqual(album1.artists?.count, 3)
		XCTAssertEqual(album1.artists?[0].id, 7553669)
		XCTAssertEqual(album1.artists?[0].name, "Jacob Collier")
		XCTAssertNil(album1.artists?[0].url)
		XCTAssertNil(album1.artists?[0].picture)
		XCTAssertNil(album1.artists?[0].popularity)
		XCTAssertEqual(album1.artists?[0].type, "MAIN")
		
		XCTAssertEqual(album1.artists?[1].id, 4631340)
		XCTAssertEqual(album1.artists?[1].name, "Metropole Orkest")
		XCTAssertNil(album1.artists?[1].url)
		XCTAssertNil(album1.artists?[1].picture)
		XCTAssertNil(album1.artists?[1].popularity)
		XCTAssertEqual(album1.artists?[1].type, "MAIN")
		
		XCTAssertEqual(album1.artists?[2].id, 4374293)
		XCTAssertEqual(album1.artists?[2].name, "Jules Buckley")
		XCTAssertNil(album1.artists?[2].url)
		XCTAssertNil(album1.artists?[2].picture)
		XCTAssertNil(album1.artists?[2].popularity)
		XCTAssertEqual(album1.artists?[2].type, "MAIN")
		
		XCTAssertEqual(album2.id, 100006800)
		XCTAssertEqual(album2.title, "Djesse Vol. 1")
		XCTAssertEqual(album2.audioQuality, .hifi)
		
		// Test Filters
		let optionalArtistAlbumsFilterEPs = session.getArtistAlbums(artistId: 7553669, filter: .epsAndSingles)
		XCTAssertNotNil(optionalArtistAlbumsFilterEPs)
		guard let artistAlbumsFilterEPs = optionalArtistAlbumsFilterEPs else {
			return
		}
		let ep = artistAlbumsFilterEPs[artistAlbumsFilterEPs.count - 1]
		XCTAssertEqual(ep.id, 84439848)
		XCTAssertEqual(ep.title, "One Day")
		
		let optionalArtistAlbumsFilterAppearances = session.getArtistAlbums(artistId: 7553669, filter: .appearances)
		XCTAssertNotNil(optionalArtistAlbumsFilterAppearances)
		guard let artistAlbumsFilterAppearances = optionalArtistAlbumsFilterAppearances else {
			return
		}
		XCTAssert(artistAlbumsFilterAppearances.count >= 10) // Probably going to be more in the future
	}
	
	func testGetArtistVideos() {
		let optionalArtistVideos = session.getArtistVideos(artistId: 7553669)
		XCTAssertNotNil(optionalArtistVideos)
		guard let artistVideos = optionalArtistVideos else {
			return
		}
		
		XCTAssert(artistVideos.count > 6)
		guard artistVideos.count > 6 else {
			return
		}
		let video1 = artistVideos[artistVideos.count - 5]
		let video2 = artistVideos[artistVideos.count - 6]
		
		XCTAssertEqual(video1.id, 98785108)
		XCTAssertEqual(video1.title, "With The Love In My Heart")
		
		XCTAssertEqual(video2.id, 107149001)
		XCTAssertEqual(video2.title, "Make Me Cry")
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
		XCTAssertEqual(artistTopTracks[0].audioModes, [.stereo])
		
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
		// Bio is not consistent, therefore cannot be tested properly.
		// Sometimes some of the referenced artists or albums have a so-called wimpLink,
		// sometimes exactly the same references don't have a wimpLink.
//		XCTAssertEqual(artistBio?.lastUpdated,
//					   DateFormatter.iso8601OptionalTime.date(from:
//						"2019-03-09T19:22:46.937GMT"))
		XCTAssertFalse(artistBio?.text.isEmpty ?? true)
//		XCTAssertEqual(artistBio?.text, "")
		
		let missingArtistBio = session.getArtistBio(artistId: 4001778)
		
		XCTAssertNil(missingArtistBio?.source)
		XCTAssertNil(missingArtistBio?.lastUpdated)
		XCTAssertNil(missingArtistBio?.text)
	}

	func testGetArtistSimilar() {
		let optionalSimilarArtists = session.getArtistSimilar(artistId: 16579)
		XCTAssertNotNil(optionalSimilarArtists)
		guard let similarArtists = optionalSimilarArtists else {
			return
		}
		
		XCTAssertEqual(similarArtists.count, 49)
		
		// Not necessarely in the same order as on website
		XCTAssertEqual(similarArtists[0].id, 10249)
		XCTAssertEqual(similarArtists[0].name, "Norah Jones")
		XCTAssertEqual(similarArtists[0].url, URL(string:
			"http://www.tidal.com/artist/10249"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(similarArtists[0].picture,
					   "70d5fe37-2326-4208-961b-7984e6605483")
		XCTAssertNotNil(similarArtists[0].popularity)
		XCTAssertNil(similarArtists[0].type)
		XCTAssertNil(similarArtists[0].banner)
		XCTAssertEqual(similarArtists[0].relationType, "SIMILAR_ARTIST")
		
		XCTAssertEqual(similarArtists[1].id, 10666)
		XCTAssertEqual(similarArtists[1].name, "Nelly Furtado")
	}

	func testGetArtistRadio() {
		// Probably needs to be updated once in a while as it can change
		
		let optionalArtistRadio = session.getArtistRadio(artistId: 16579)
		XCTAssertNotNil(optionalArtistRadio)
		guard let artistRadio = optionalArtistRadio else {
			return
		}
		
		XCTAssertEqual(artistRadio.count, 100)
		
		// Impossible to write consistent tests as the tracks are regularly changing
		
//		XCTAssertEqual(artistRadio[0].id, 70974091)
//		XCTAssertEqual(artistRadio[0].title, "Ich atme ein")
//		XCTAssertEqual(artistRadio[0].duration, 209)
//		XCTAssertEqual(artistRadio[0].replayGain, -11.04)
//		XCTAssertEqual(artistRadio[0].peak, 0.978058)
//		XCTAssertEqual(artistRadio[0].allowStreaming, true)
//		XCTAssertEqual(artistRadio[0].streamReady, true)
//		XCTAssertEqual(artistRadio[0].streamStartDate,
//					   DateFormatter.iso8601OptionalTime.date(from: "2017-03-17"))
//		XCTAssertEqual(artistRadio[0].trackNumber, 5)
//		XCTAssertEqual(artistRadio[0].volumeNumber, 1)
//		//		print(artistTopTracks[0].popularity)
//		XCTAssertEqual(artistRadio[0].copyright,
//					   "(P) 2006 CICEU/HDW/RAMOND/HASS")
//		XCTAssertEqual(artistRadio[0].url,
//					   URL(string: "http://www.tidal.com/track/70974091"))
//		XCTAssertEqual(artistRadio[0].isrc, "DEA620600145")
//		XCTAssertEqual(artistRadio[0].editable, false)
//		XCTAssertEqual(artistRadio[0].explicit, false)
//		XCTAssertEqual(artistRadio[0].audioQuality, .hifi)
//		XCTAssertEqual(album.audioModes, [.stereo])
		
		// Artists
		XCTAssertEqual(artistRadio[0].artists.count, 1)
		XCTAssertEqual(artistRadio[0].artists[0].id, 16579)
		XCTAssertEqual(artistRadio[0].artists[0].name, "Roger Cicero")
		XCTAssertEqual(artistRadio[0].artists[0].type, "MAIN")
		
		// Album
//		XCTAssertEqual(artistRadio[0].album.id, 70974086)
//		XCTAssertEqual(artistRadio[0].album.title, "Glück ist leicht - Das Beste von 2006 - 2016")
		
		// More Tracks
//		XCTAssertEqual(artistRadio[1].id, 58965655)
//		XCTAssertEqual(artistRadio[1].title, "Du erinnerst mich an Liebe")
//		XCTAssertEqual(artistRadio[1].artists[0].id, 3673052)
//		XCTAssertEqual(artistRadio[1].artists[0].name, "Ich + Ich")
//		XCTAssertEqual(artistRadio[2].id, 36309894)
//		XCTAssertEqual(artistRadio[2].title, "Symphonie (On Stage)")
//		XCTAssertEqual(artistRadio[2].artists[0].id, 2771)
//		XCTAssertEqual(artistRadio[2].artists[0].name, "Silbermond")
	}
	
	func testGetTrackRadio() {
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
		XCTAssertEqual(playlists[18].uuid, "825a0e70-c918-40b8-89c6-247dfbac04b4")
		// Testing the handling of "" in Strings & JSON
		XCTAssertEqual(playlists[18].title, #"Schlechte "Musik""#)
		XCTAssertEqual(playlists[18].type, .user)
		XCTAssertEqual(playlists[18].creator.id, userId)
		XCTAssertNil(playlists[18].creator.name)
		XCTAssertNil(playlists[18].creator.url)
		XCTAssertNil(playlists[18].creator.picture)
		XCTAssertNil(playlists[18].creator.popularity)
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
		let optionalMixes = session.getMixes()
		XCTAssertNotNil(optionalMixes)
		guard let mixes = optionalMixes else {
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
					   "Step onto your mat and into your zen with these meditative tracks. (Photo: Unsplash)")
//		XCTAssertEqual(playlists[0].duration, 18592)
		XCTAssertEqual(playlists[0].created,
					   DateFormatter.iso8601OptionalTime.date(from: "2018-02-05T21:44:05.249GMT"))
		XCTAssertEqual(playlists[0].publicPlaylist, true)
		XCTAssertEqual(playlists[0].url, URL(string:
			"http://www.tidal.com/playlist/98676f10-0aa1-4c8c-ba84-4f84e370f3d2"))
		XCTAssertEqual(playlists[0].image, "51179e26-5245-42d9-a689-7eac460dfba1")
		XCTAssertEqual(playlists[0].squareImage, "12133a11-be8b-4c27-83bd-d756e4072ac4")
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
	
	
	// MARK: - Favorites
	
	// Return
	
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
		XCTAssertEqual(nameAsc?.reversed(), nameDesc)

		let artistAsc = favorites.albums(order: .artist, orderDirection: .ascending)
		let artistDesc = favorites.albums(order: .artist, orderDirection: .descending)
		XCTAssertNotNil(artistAsc)
		XCTAssertNotNil(artistDesc)
		XCTAssertEqual(artistAsc?.reversed(), artistDesc)

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
		XCTAssertEqual(releaseAscDates.reversed(), releaseDescDates)
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
		XCTAssertEqual(dateAsc?.reversed(), dateDesc)
		
		let nameAsc = favorites.playlists(order: .name, orderDirection: .ascending)
		let nameDesc = favorites.playlists(order: .name, orderDirection: .descending)
		XCTAssertNotNil(nameAsc)
		XCTAssertNotNil(nameDesc)
		XCTAssertEqual(nameAsc?.reversed(), nameDesc)
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
	
	// Add & Delete
	// Make sure you don't have the chosen artist, album etc. in your favorites
	// The respective artist, album etc. will be gone after the tests
	
	func testArtistAddAndDelete() {
		let demoArtistId = 7771771
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
		
		let r1 = favorites.addArtist(artistId: demoArtistId)
		XCTAssert(r1)
		
		XCTAssert((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
		
		let r2 = favorites.removeArtist(artistId: demoArtistId)
		XCTAssert(r2)
		
		XCTAssertFalse((favorites.artists()?.contains { (artist) -> Bool in
			artist.item.id == demoArtistId
		})!)
	}
	
	func testAlbumAddAndDelete() {
		let demoAlbumId = 65929420
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
		
		let r1 = favorites.addAlbum(albumId: demoAlbumId)
		XCTAssert(r1)
		
		XCTAssert((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
		
		let r2 = favorites.removeAlbum(albumId: demoAlbumId)
		XCTAssert(r2)
		
		XCTAssertFalse((favorites.albums()?.contains { (album) -> Bool in
			album.item.id == demoAlbumId
		})!)
	}
	
	func testTrackAddAndDelete() {
		let demoTrackId = 65929421
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
		
		let r1 = favorites.addTrack(trackId: demoTrackId)
		XCTAssert(r1)
		
		XCTAssert((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
		
		let r2 = favorites.removeTrack(trackId: demoTrackId)
		XCTAssert(r2)
		
		XCTAssertFalse((favorites.tracks()?.contains { (track) -> Bool in
			track.item.id == demoTrackId
		})!)
	}
	
	func testVideoAddAndDelete() {
		let demoVideoId = 104569734
		
		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}
		
		XCTAssertFalse((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
		
		let r1 = favorites.addVideo(videoId: demoVideoId)
		XCTAssert(r1)
		
		XCTAssert((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
		
		let r2 = favorites.removeVideo(videoId: demoVideoId)
		XCTAssert(r2)

		XCTAssertFalse((favorites.videos()?.contains { (video) -> Bool in
			video.item.id == demoVideoId
		})!)
	}
	
	func testPlaylistAddAndDelete() {
		let demoPlaylistId = "627c2039-ef15-46b2-9891-3773dd3d5aa5"

		XCTAssertNotNil(session.favorites)
		guard let favorites = session.favorites else {
			return
		}

		XCTAssertFalse((favorites.playlists()?.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		})!)

		let r1 = favorites.addPlaylist(playlistId: demoPlaylistId)
		XCTAssert(r1)

		XCTAssert((favorites.playlists()?.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		})!)

		let r2 = favorites.removePlaylist(playlistId: demoPlaylistId)
		XCTAssert(r2)

		XCTAssertFalse((favorites.playlists()?.contains { (playlist) -> Bool in
			playlist.playlist.uuid == demoPlaylistId
		})!)
	}
	
	
	// MARK: - Playlist Editing
	
	func testPlaylistEditing() {
		let demoTrackId1 = 59978883
		let demoTrackId2 = 59978884
		let demoVideoId = 98785108
		
		XCTAssertNotNil(session.userId)
		guard let userId = session.userId else {
			return
		}
		
		// Before
		
		let userPlaylistCountBefore = session.getUserPlaylists(userId: userId)?.count
		
		// Create Playlist
		
		let optionalPlaylist1 = session.createPlaylist(title: "Test", description: "Test Description")
		XCTAssertNotNil(optionalPlaylist1)
		guard let playlist1 = optionalPlaylist1 else {
			return
		}
		
		XCTAssertEqual(playlist1.title, "Test")
		XCTAssertEqual(playlist1.description, "Test Description")
		XCTAssertEqual(playlist1.creator.id, session.userId)
		XCTAssertEqual(playlist1.numberOfTracks, 0)
		XCTAssertEqual(playlist1.numberOfVideos, 0)

		// Add Track
		
		let r1 = session.addTracks([demoTrackId1, demoTrackId2], to: playlist1.uuid, duplicate: false)
		XCTAssert(r1)

		let optionalPlaylist2 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist2)
		guard let playlist2 = optionalPlaylist2 else {
			return
		}

		XCTAssertEqual(playlist2.numberOfTracks, 2)
		XCTAssertEqual(playlist2.numberOfVideos, 0)
		
		let optionalPlaylist2Tracks = session.getPlaylistTracks(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist2Tracks)
		guard let playlist2Tracks = optionalPlaylist2Tracks else {
			return
		}
		
		XCTAssertEqual(playlist2Tracks[0].id, 59978883)
		XCTAssertEqual(playlist2Tracks[1].id, 59978884)
		
		// Add Video
		
		let r2 = session.addTrack(demoVideoId, to: playlist1.uuid, duplicate: false)
		XCTAssert(r2)

		let optionalPlaylist3 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist3)
		guard let playlist3 = optionalPlaylist3 else {
			return
		}

		XCTAssertEqual(playlist3.numberOfTracks, 2)
		XCTAssertEqual(playlist3.numberOfVideos, 1)
		
		let optionalPlaylist3Tracks = session.getPlaylistTracks(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist3Tracks)
		guard let playlist3Tracks = optionalPlaylist3Tracks else {
			return
		}
		
		XCTAssertEqual(playlist3Tracks[0].id, 59978883) // Track
//		XCTAssertEqual(playlist3Tracks[2].id, 98785108) // Video
		XCTAssertEqual(playlist3Tracks[2].id, 98785110) // Video
		// For some reason after adding it, the Video ID changes. Possibly has something to do with regions:
		// https://github.com/jackfagner/OpenTidl/issues/5
		// 98785110 is actually a track when I try to add it.
		// When adding 98785108 the resulting 98785110 in the playlist is a video (and is counted as such).
		
		// Move Video from position 2 to 0
		
		let r3 = session.moveTrack(from: 2, to: 0, in: playlist1.uuid)
		XCTAssert(r3)
		
		let optionalPlaylist4Tracks = session.getPlaylistTracks(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist4Tracks)
		guard let playlist4Tracks = optionalPlaylist4Tracks else {
			return
		}
		
		XCTAssertEqual(playlist4Tracks.count, 3)
		
//		XCTAssertEqual(playlist4Tracks[0].id, 98785108) // Video (same problem as above)
		XCTAssertEqual(playlist4Tracks[0].id, 98785110) // Video
		XCTAssertEqual(playlist4Tracks[1].id, 59978883) // Track
		XCTAssertEqual(playlist4Tracks[2].id, 59978884) // Track
		
		// Remove Track

		let r4 = session.removeTrack(index: 2, from: playlist1.uuid)
		XCTAssert(r4)

		let optionalPlaylist5 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist5)
		guard let playlist5 = optionalPlaylist5 else {
			return
		}

		XCTAssertEqual(playlist5.numberOfTracks, 1)
		XCTAssertEqual(playlist5.numberOfVideos, 1)
		
		// Edit Playlist name and description
		
		let r5 = session.editPlaylist(playlistId: playlist1.uuid, title: "Changed Test", description: "Changed Description")
		XCTAssert(r5)

		let optionalPlaylist6 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist6)
		guard let playlist6 = optionalPlaylist6 else {
			return
		}

		XCTAssertEqual(playlist6.title, "Changed Test")
		XCTAssertEqual(playlist6.description, "Changed Description")
		
		// Delete Playlist
		
		let r6 = session.deletePlaylist(playlistId: playlist1.uuid)
		XCTAssert(r6)

		let userPlaylistCountAfter = session.getUserPlaylists(userId: userId)?.count
		XCTAssertEqual(userPlaylistCountBefore, userPlaylistCountAfter)
	}
	
	// MARK: - Artist String
	
	func testFormArtistString() {
		let artist1 = session.getArtist(artistId: 7553669)!
		let artist2 = session.getArtist(artistId: 4631340)!
		let artist3 = session.getArtist(artistId: 4374293)!
		
		let noArtist = [Artist]()
		XCTAssertEqual(noArtist.formArtistString(), "")
		
		let oneArtist = [artist1]
		XCTAssertEqual(oneArtist.formArtistString(), "Jacob Collier")
		
		let twoArtists = [artist1, artist2]
		XCTAssertEqual(twoArtists.formArtistString(), "Jacob Collier & Metropole Orkest")
		
		let threeArtists = [artist1, artist2, artist3]
		XCTAssertEqual(threeArtists.formArtistString(), "Jacob Collier, Metropole Orkest & Jules Buckley")
	}
	
	// MARK: - Date
	
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
	
	func testDateOnlyFormatter() {
		let rawString = "2019-03-28T06:49:21.123GMT"
		let date = DateFormatter.iso8601OptionalTime.date(from: rawString)!
		let formattedDateString = DateFormatter.dateOnly.string(from: date)
		XCTAssertEqual(formattedDateString, "28. March 2019")
	}

}
