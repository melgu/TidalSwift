//
//  HelpersTests.swift
//  TidalSwiftTests
//
//  Created by Melvin Gundlach on 28.05.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwift

class HelpersTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: readDemoLoginCredentials()))
	var helpers: Helpers?
	
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
		helpers = Helpers(session: session)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testInit() {
		XCTAssertNotNil(helpers)
	}

    func testNewReleasesFromFavoriteArtists() {
		// Warning: Can also fail if you don't have favorite artists with a total of at least 30 albums
		let optionalAlbums = helpers?.newReleasesFromFavoriteArtists(number: 30)
		XCTAssertNotNil(optionalAlbums)
		guard let albums = optionalAlbums else {
			return
		}
		XCTAssertEqual(albums.count, 30)
		XCTAssert(albums[0].releaseDate! > albums[29].releaseDate!)
//		for album in albums {
//			print("\(album.artist!.name) - \(album.title) - \(album.releaseDate!)")
//		}
    }

}
