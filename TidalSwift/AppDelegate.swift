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
	
	let username = ""
	let password = ""

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		let config = Config(quality: .lossless)
		let session = Session(config: config)
		
		print(session.login(username: username, password: password))
		print(session.checkLogin())
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

