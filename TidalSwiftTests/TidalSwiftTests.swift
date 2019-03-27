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
	
	var session: Session = Session(config: Config(quality: .LOSSLESS))

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		let config = Config(quality: .LOSSLESS)
		session = Session(config: config)
		
		let loginInfo = session.readDemoLoginInformation()
		_ = session.login(username: loginInfo.username, password: loginInfo.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		
		session.deletePersistantInformation()
    }
	
	func testSaveAndLoadSession() {
		let tempSessionId = session.sessionId
		let tempCountryCode = session.countryCode
		let tempUserId = session.user!.id
		
		session.saveSession()
		session.loadSession()
		
		XCTAssertEqual(tempSessionId, session.sessionId)
		XCTAssertEqual(tempCountryCode, session.countryCode)
		XCTAssertEqual(tempUserId, session.user!.id)
	}
	
	func testSaveAndLoadLogin() {
		let loginInfo = session.readDemoLoginInformation()
		
		session.saveLoginInformation(loginInformation: loginInfo)
		let permanentLoginInfoOptional = session.loadLoginInformation()
		
		XCTAssertNotNil(permanentLoginInfoOptional)
		
		guard let permanentLoginInfo = permanentLoginInfoOptional else {
			return
		}
		
		XCTAssertEqual(permanentLoginInfo.username, loginInfo.username)
		XCTAssertEqual(permanentLoginInfo.password, loginInfo.password)
	}
	
	func testSaveAndLoadConfig() {
		session.saveConfig()
		let permanentConfigOptional = session.loadConfig()
		
		XCTAssertNotNil(permanentConfigOptional)
		
		guard let permanentConfig = permanentConfigOptional else {
			return
		}
		
		XCTAssertEqual(permanentConfig.quality, session.config.quality)
		XCTAssertEqual(permanentConfig.apiLocation, session.config.apiLocation)
		XCTAssertEqual(permanentConfig.apiToken, session.config.apiToken)
		XCTAssertEqual(permanentConfig.imageUrl, session.config.imageUrl)
		XCTAssertEqual(permanentConfig.imageSize, session.config.imageSize)
	}
	
	func testLogin() {
		let loginInfo = session.readDemoLoginInformation()
		
		let config = Config(quality: .LOSSLESS)
		session = Session(config: config)
		
		let result = session.login(username: loginInfo.username, password: loginInfo.password)
		
		XCTAssert(result)
	}
	
	func testCheckLogin() {
		XCTAssert(session.checkLogin())
		
		let config = Config(quality: .LOSSLESS)
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
		let searchResultArtist = session.search(for: "Jacob Collier")
		XCTAssertEqual(searchResultArtist?.artists.totalNumberOfItems, 1)
		XCTAssertEqual(searchResultArtist?.artists.offset, 0)
		XCTAssertEqual(searchResultArtist?.artists.items[0].id, 7553669)
		XCTAssertEqual(searchResultArtist?.artists.items[0].name, "Jacob Collier")
		XCTAssertEqual(searchResultArtist?.artists.items[0].url,
					   URL(string: "http://www.tidal.com/artist/7553669"))
		// Interestingly the resulting URL is HTTP instead of HTTPS
		XCTAssertEqual(searchResultArtist?.artists.items[0].picture,
					   "daaa931c-afc0-4c63-819c-c821393b6a45")
		XCTAssertNotNil(searchResultArtist?.artists.items[0].popularity)
		XCTAssertNil(searchResultArtist?.artists.items[0].type)
	}
	
	func testSearchAlbum() {
		let searchResultAlbum = session.search(for: "Jacob Collier In My Room")
		XCTAssertEqual(searchResultAlbum?.albums.totalNumberOfItems, 1)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].id, 59978881)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].title, "In My Room")
		XCTAssertEqual(searchResultAlbum?.albums.items[0].duration, 3531)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].streamReady, true)
		XCTAssertNotNil(searchResultAlbum?.albums.items[0].streamStartDate)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].allowStreaming, true)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].numberOfTracks, 11)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].numberOfVideos, 0)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].numberOfVolumes, 1)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].releaseDate,
					   DateFormatter.iso8601OptionalTime.date(from: "2016-07-15"))
		XCTAssertEqual(searchResultAlbum?.albums.items[0].copyright, "2016 Membran")
		XCTAssertNotNil(searchResultAlbum?.albums.items[0].popularity)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].audioQuality, "LOSSLESS")
		
		// Album Artist
		XCTAssertEqual(searchResultAlbum?.albums.items[0].artists?.count, 1)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].artists?[0].id, 7553669)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].artists?[0].name, "Jacob Collier")
		XCTAssertNil(searchResultAlbum?.albums.items[0].artists?[0].url)
		XCTAssertNil(searchResultAlbum?.albums.items[0].artists?[0].picture)
		XCTAssertNil(searchResultAlbum?.albums.items[0].artists?[0].popularity)
		XCTAssertEqual(searchResultAlbum?.albums.items[0].artists?[0].type, "MAIN")
	}
	
	func testSearchTopHit() {
		let searchResultTopHit = session.search(for: "Jacob Collier")
		XCTAssertEqual(searchResultTopHit?.topHit?.value.id, 7553669)
		XCTAssertNotNil(searchResultTopHit?.topHit?.value.popularity)
		XCTAssertNil(searchResultTopHit?.topHit?.value.uuid)
	}
	
	func testDateDecoder() {
		// Tests if the DateDecoder defined at the bottom of Codable correctly decodes a date. Makes sure there is no time zone switching.
		let rawString = "2016-07-15"
		let resultString = "2016-07-15 00:00:00 +0000"
		let date = DateFormatter.iso8601OptionalTime.date(from: rawString)!
		XCTAssertEqual(resultString, "\(date)")
	}

}
