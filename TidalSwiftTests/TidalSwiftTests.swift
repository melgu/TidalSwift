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
		
		let loginInfo = session.readLoginInformationFromFile(path: "Demo Login Information")
		_ = session.login(username: loginInfo.username, password: loginInfo.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testLoadSession() {
		let temp = PersistentInformation(sessionId: session.sessionId!, countryCode: session.countryCode!, userId: session.user!.id)
		
		let config = Config(quality: .LOSSLESS)
		session = Session(config: config)
		session.loadSession(userId: temp.userId, sessionId: temp.sessionId, countryCode: temp.countryCode)
		
		let result = session.checkLogin()
		XCTAssert(result)
	}
	
	func testWriteAndReadLogin() {
		let testInfo = session.readLoginInformationFromFile(path: "Demo Login Information")
		
		// Write
		session.writeLoginInformationToFile(loginInformation: testInfo)
		
		// Read back
		let loginInfo = session.readLoginInformationFromFile()
		
		XCTAssertEqual(loginInfo.username, testInfo.username)
		XCTAssertEqual(loginInfo.password, testInfo.password)
	}
	
	func testLogin() {
		let loginInfo = session.readLoginInformationFromFile()
		
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
