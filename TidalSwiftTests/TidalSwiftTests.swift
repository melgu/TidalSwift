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
	}
	
	func testGetSubscriptionInfo() {
		let info = session.getSubscriptionInfo()
		XCTAssertNotNil(info)
	}
	
	func testGetMediaUrl() {
		let url = session.getMediaUrl(trackId: 73034791)
		XCTAssertNotNil(url)
	}
	
	func testSearch() {
		let searchResult = session.search(for: "Rolf Zuckowski")
		XCTAssertNotNil(searchResult)
	}

}
