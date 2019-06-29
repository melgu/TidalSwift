//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var mainViewController: ViewController?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
//		let loginCredentials = readDemoLoginCredentials()
//		let config = Config(quality: .hifi, loginCredentials: loginCredentials)
//		let session = Session(config: config)
//
//		session.deletePersistantInformation()
//
//		_ = session.login()
//		print(session.checkLogin())
//		
//		print(loginCredentials.username)
//		print(loginCredentials.password)
//		print(config.apiToken)
//		print(session.sessionId)
//
//		session.saveConfig()
//		session.saveSession()
		
		
//		let session = Session(config: nil)
//		session.loadSession()
//		print("Login: \(session.checkLogin())")
//
//		let helpers = Helpers(session: session)
		
//		let albums = helpers.newReleasesFromFavoriteArtists(number: 100)!
//		for album in albums {
//			print("\(album.artist!.name) - \(album.title) - \(album.releaseDate!)")
//		}
		
//		let r = helpers.downloadTrack(track: session.getTrack(trackId: 110386812)!)
//		let r = helpers.downloadAlbum(album: session.getAlbum(albumId: 59978881)!)
//		print(r)
		
		
		print("-----")
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
		
		UserDefaults.standard.synchronize()
	}


}
