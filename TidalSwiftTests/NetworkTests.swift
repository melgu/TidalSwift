//
//  NetworkTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 27.06.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwift

class NetworkTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	let demoFolderName = "TidalSwift_Test"
	let demoName = "Test_Captive.html"
	let demoUrl = URL(string: "https://captive.apple.com")!
	let demoContent = "<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>\n"
	

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		
		do {
			var path = try FileManager.default.url(for: .downloadsDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(demoFolderName)
			if FileManager.default.fileExists(atPath: path.relativePath) {
				try FileManager.default.removeItem(at: path)
			}
		} catch {
			print(error)
		}
    }
	
	func testGet() {
		let response = get(url: demoUrl, parameters: [:])
		XCTAssert(response.ok)
		XCTAssertNotNil(response.statusCode)
		XCTAssertNotNil(response.content)
		if let content = response.content {
			let contentString = String(data: content, encoding: String.Encoding.utf8)
			XCTAssertEqual(contentString, demoContent)
		}
		XCTAssertNil(response.etag)
	}

	func testDownload() {
		let response = download(demoUrl,
								baseLocation: .downloads,
								targetPath: demoFolderName,
								name: demoName)
		XCTAssert(response.ok)
		XCTAssertNotNil(response.statusCode)
		XCTAssertNil(response.content)
		XCTAssertNil(response.etag)
		
		do {
			var path = try FileManager.default.url(for: .downloadsDirectory,
												   in: .userDomainMask,
												   appropriateFor: nil,
												   create: false)
			path.appendPathComponent(demoFolderName)
			path.appendPathComponent(demoName)
			XCTAssert(FileManager.default.fileExists(atPath: path.relativePath))
			let content = try String(contentsOf: path)
			XCTAssertEqual(content, demoContent)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}

}
