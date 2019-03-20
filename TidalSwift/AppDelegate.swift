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
	
	func importLoginInformation() -> LoginInformation {
		let fileLocation = Bundle.main.path(forResource: "Login Information", ofType: "txt")!
		var content = ""
		do {
			content = try String(contentsOfFile: fileLocation)
			print(content)
		} catch {
			print("Error Reading Login Information")
		}
		
		let lines: [String] = content.components(separatedBy: "\n")
		let result = LoginInformation(username: lines[0], password: lines[1])
		
		return result
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		let loginInfo = importLoginInformation()
		
		let config = Config(quality: .LOSSLESS)
		let session = Session(config: config)

		print(session.login(username: loginInfo.username, password: loginInfo.password))
		print(session.checkLogin())
		
//		print(session.getMediaUrl(trackId: 73034791)!)
		
		let searchResponse = session.search(for: "Rolf Zuckowski", limit: 2)
		print(searchResponse?.artists.totalNumberOfItems)
		print(searchResponse?.topHit)
		print(searchResponse?.topHit?.type)
		print(searchResponse?.topHit?.value.id)
		print(searchResponse?.topHit?.value.popularity)
		
		print("-----")
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}
