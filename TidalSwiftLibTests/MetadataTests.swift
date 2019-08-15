//
//  MetadataTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 25.07.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class MetadataTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	var metadata: Metadata?
	
	let demoFolderName = "TidalSwift_Test_Metadata"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
		metadata = Metadata(session: session)
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
	
	func testInit() {
		XCTAssertNotNil(metadata)
	}
	
	func testSetMetadata() {
//		let helpers = Helpers(session: session)
//
//		let optionalTrack = session.getTrack(trackId: 100006880)
//		XCTAssertNotNil(optionalTrack)
//		guard let track = optionalTrack else {
//			return
//		}
//
//		let r = helpers.downloadTrack(track: track, parentFolder: demoFolderName)
//		XCTAssert(r)
//
//		let optionalPath = buildPath(baseLocation: .downloads, parentFolder: demoFolderName,
//									 name: helpers.formFileName(track))
//		XCTAssertNotNil(optionalPath)
//		guard let path = optionalPath else {
//			return
//		}
//
//		let m4aFile: MP42File
//		do {
//			print(track.title)
//			print(path)
//			m4aFile = try MP42File(url: path)
//		} catch {
//			print(error)
//			XCTFail(error.localizedDescription)
//			return
//		}
//
//		XCTAssertEqual(m4aFile.metadata.items.count, 9)
	}
    
}
