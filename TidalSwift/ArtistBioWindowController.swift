//
//  ArtistBioWindowController.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

class ArtistBioWindowController<RootView : View>: NSWindowController {
	convenience init(rootView: RootView) {
		let hostingController = NSHostingController(rootView: rootView)
		let window = NSWindow(contentViewController: hostingController)
		window.setContentSize(NSSize(width: 640, height: 640))
		window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
		window.center()
		self.init(window: window)
	}
}
