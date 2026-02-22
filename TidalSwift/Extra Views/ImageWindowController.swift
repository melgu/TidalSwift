//
//  CoverWindowController.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 29.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

#if canImport(AppKit)
class ImageWindowController: NSWindowController {
	convenience init(imageUrl: URL, title: String) {
		let hostingController = NSHostingController(rootView: ImageWindowView(imageUrl: imageUrl, title: title)
				.frame(width: 640, height: 640))
		let window = NSWindow(contentViewController: hostingController)
		window.setContentSize(NSSize(width: 640, height: 640))
		window.center()
		self.init(window: window)
	}
}
#endif

struct ImageWindowView: View {
	let imageUrl: URL
	let title: String
	
	var body: some View {
		AsyncImage(url: imageUrl) { image in
			image.resizable().scaledToFit()
		} placeholder: {
			Rectangle()
		}
	}
}
