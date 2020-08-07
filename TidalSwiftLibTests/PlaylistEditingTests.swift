//
//  PlaylistEditingTests.swift
//  TidalSwiftLibTests
//
//  Created by Melvin Gundlach on 07.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class PlaylistEditingTests: XCTestCase {
	
	var session: Session = Session(config: Config(quality: .hifi, loginCredentials: LoginCredentials(username: "", password: ""), urlType: .offline))
	
	var tempConfig: Config?
	var tempSession: Session?
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		// Before messing with UserDefaults, load Session with saved values into variable
		tempSession = Session(config: nil)
		_ = tempSession?.loadSession()
		
		// Now, we are free to mess around
		session = Session(config: nil) // Config is loaded from persistent storage
		
		_ = session.loadSession()
		if !session.checkLogin() {
			_ = session.login()
		}
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		
		// Delete UserDefaults
		session.deletePersistentInformation()
		
		// Save back old UserDefaults
		tempSession?.saveConfig()
		tempSession?.saveSession()
	}
	
	func testPlaylistEditing() {
		let demoTrackId1 = 59978883
		let demoTrackId2 = 59978884
		let demoVideoId = 98785108
		
		XCTAssertNotNil(session.userId)
		guard let userId = session.userId else {
			return
		}
		
		guard let demoTrack1 = session.getTrack(trackId: demoTrackId1),
			  let demoTrack2 = session.getTrack(trackId: demoTrackId2),
			  let demoVideo = session.getVideo(videoId: demoVideoId) else {
			XCTFail("demoTrack1, demoTrack2 or demoVideo is nil")
			return
		}
		
		// Before
		
		let userPlaylistCountBefore = session.getUserPlaylists(userId: userId)?.count
		
		// Create Playlist
		
		let optionalPlaylist1 = session.playlistEditing.create(title: "Test", description: "Test Description")
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
		
		let r1 = playlist1.addTracks([demoTrack1, demoTrack2], duplicate: false, session: session)
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
		
		let r2 = playlist1.addVideo(demoVideo, duplicate: false, session: session)
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
		
		let r3 = playlist1.moveItem(fromIndex: 2, toIndex: 0, session: session)
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
		
		let r4 = playlist1.removeItem(atIndex: 2, session: session)
		XCTAssert(r4)
		
		let optionalPlaylist5 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist5)
		guard let playlist5 = optionalPlaylist5 else {
			return
		}
		
		XCTAssertEqual(playlist5.numberOfTracks, 1)
		XCTAssertEqual(playlist5.numberOfVideos, 1)
		
		// Edit Playlist name and description
		
		let r5 = playlist1.edit(title: "Changed Test", description: "Changed Description", session: session)
		XCTAssert(r5)
		
		let optionalPlaylist6 = session.getPlaylist(playlistId: playlist1.uuid)
		XCTAssertNotNil(optionalPlaylist6)
		guard let playlist6 = optionalPlaylist6 else {
			return
		}
		
		XCTAssertEqual(playlist6.title, "Changed Test")
		XCTAssertEqual(playlist6.description, "Changed Description")
		
		// Delete Playlist
		
		let r6 = playlist1.delete(session: session)
		XCTAssert(r6)
		
		let userPlaylistCountAfter = session.getUserPlaylists(userId: userId)?.count
		XCTAssertEqual(userPlaylistCountBefore, userPlaylistCountAfter)
	}
}
