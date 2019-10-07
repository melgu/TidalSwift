//
//  ArtistBioWindowController.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

class ResizableWindowController<RootView : View>: NSWindowController {
	convenience init(rootView: RootView, width: Int = 420, height: Int = 640) {
		let hostingController = NSHostingController(rootView: rootView)
		let window = NSWindow(contentViewController: hostingController)
		window.setContentSize(NSSize(width: width, height: height))
		window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
		window.center()
		self.init(window: window)
	}
}
