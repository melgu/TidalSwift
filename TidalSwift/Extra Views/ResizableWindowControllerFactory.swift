//
//  ResizableWindowControllerFactory.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.02.26.
//

import SwiftUI

#if canImport(AppKit)
enum ResizableWindowControllerFactory {
	static func create<RootView: View>(rootView: RootView, width: Int = 420, height: Int = 640) -> NSWindowController {
		let hostingController = NSHostingController(rootView: rootView)
		let window = NSWindow(contentViewController: hostingController)
		window.setContentSize(NSSize(width: width, height: height))
		window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
		window.center()
		return NSWindowController(window: window)
	}
}
#endif
