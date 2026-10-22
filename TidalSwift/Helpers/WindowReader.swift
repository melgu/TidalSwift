//
//  WindowReader.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import SwiftUI

#if canImport(AppKit)
/// Reports the window the view is placed in, as SwiftUI doesn't expose it
struct WindowReader: NSViewRepresentable {
	let onWindow: (NSWindow?) -> Void
	
	func makeNSView(context: Context) -> WindowReaderView {
		let view = WindowReaderView()
		view.onWindow = onWindow
		return view
	}
	
	func updateNSView(_ nsView: WindowReaderView, context: Context) {
		nsView.onWindow = onWindow
	}
	
	final class WindowReaderView: NSView {
		var onWindow: ((NSWindow?) -> Void)?
		
		override func viewDidMoveToWindow() {
			super.viewDidMoveToWindow()
			onWindow?(window)
		}
	}
}
#endif
