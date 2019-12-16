//
//  HelpersTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 28.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class HelpersTests: XCTestCase {
	
//	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: LoginCredentials(username: "", password: "")))
	var helpers: Helpers { session.helpers }
	
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		_ = session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testInit() {
		XCTAssertNotNil(helpers)
	}

    func testNewReleasesFromFavoriteArtists() {
		// Warning: Can also fail if you don't have favorite artists with a total of at least 30 albums
		let optionalAlbums = helpers.newReleasesFromFavoriteArtists(number: 30)
		XCTAssertNotNil(optionalAlbums)
		guard let albums = optionalAlbums else {
			return
		}
		XCTAssertEqual(albums.count, 30)
		guard albums.count >= 30 else {
			return
		}
		XCTAssert(albums[0].releaseDate! > albums[29].releaseDate!)
//		for album in albums {
//			print("\(album.artist!.name) - \(album.title) - \(album.releaseDate!)")
//		}
    }

}
