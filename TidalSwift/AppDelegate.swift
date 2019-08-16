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
	
	var session: Session?


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		// My Stuff
		let config = Config(quality: .hifi,
							loginCredentials: readDemoLoginCredentials(),
							apiToken: nil)
		session = Session(config: config)
		
//		session?.login()
//		session?.saveConfig()
//		session?.saveSession()
		
		session?.loadSession()
		
		let demoAlbum = session!.getAlbum(albumId: 100006868)!
		
		print("-----")
		
		// Swift UI Stuff
		window = NSWindow(
		    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
		    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
		    backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")

		window.contentView = NSHostingView(rootView: ContentView())

		window.makeKeyAndOrderFront(nil)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	
	func readDemoLoginCredentials() -> LoginCredentials {
		let fileLocation = Bundle.main.path(forResource: "Demo Login Information", ofType: "txt")!
		var content = ""
		do {
			content = try String(contentsOfFile: fileLocation)
		} catch {
			print("I'm unhappy in AppDelegate")
		}

		let lines: [String] = content.components(separatedBy: "\n")
		return LoginCredentials(username: lines[0], password: lines[1])
	}
	
}

