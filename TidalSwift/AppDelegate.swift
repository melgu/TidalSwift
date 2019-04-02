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
		
//		let loginInfo = readDemoLoginInformation()
//		let config = Config(loginInformation: loginInfo)
		let session = Session(config: nil)
		
		session.loadSession()
		
		print(session.checkLogin())
		
		print("-----")
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
		
		UserDefaults.standard.synchronize()
	}


}
