//
//  AppDelegate.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa
import SwiftUI
import TidalSwiftLib

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var window: NSWindow!
	
	var session: Session
	let player: Player
	
	override init() {
		func readDemoLoginCredentials() -> LoginCredentials {
			let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
			var content = ""
			do {
				content = try String(contentsOfFile: fileLocation)
			} catch {
				print("AppDelegate: readDemoLoginCredentials can't open Demo file")
			}

			let lines: [String] = content.components(separatedBy: "\n")
			return LoginCredentials(username: lines[0], password: lines[1])
		}
		
		let config = Config(quality: .hifi,
							loginCredentials: readDemoLoginCredentials(),
							apiToken: nil)
		session = Session(config: config)
		player = Player(session: session)
		
		super.init()
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		// My Stuff
		
//		session?.login()
//		session?.saveConfig()
//		session?.saveSession()
		
//		session.loadSession()
//		
//		let demoAlbum = session.getAlbum(albumId: 100006868)!
//		let demoTracks = session.getAlbumTracks(albumId: demoAlbum.id)!
//		
//		player.addNow(tracks: demoTracks)
//		print(player.queueCount())
//		player.play()
		
		
		print("-----")
		
		// Swift UI Stuff
		window = NSWindow(
		    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
		    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // Comment out the last if issue of content being too high at launch persists
		    backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")

		window.contentView = NSHostingView(rootView: ContentView(session: session, player: player, playbackInfo: player.playbackInfo))

		window.makeKeyAndOrderFront(nil)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
}

