//
//  ResizableWindowControllerFactory.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.02.26.
//

import SwiftUI

#if canImport(AppKit)
enum ResizableWindowControllerFactory {
	/// With an `autosaveName`, the window's frame persists across app launches
	static func create<RootView: View>(rootView: RootView, width: Int = 420, height: Int = 640, autosaveName: String? = nil) -> NSWindowController {
		let hostingController = NSHostingController(rootView: rootView)
		let window = NSWindow(contentViewController: hostingController)
		window.setContentSize(NSSize(width: width, height: height))
		window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
		window.center()
		if let autosaveName {
			// Restores a saved frame, so it must come after center()
			window.setFrameAutosaveName(autosaveName)
		}
		return NSWindowController(window: window)
	}
}
#endif
