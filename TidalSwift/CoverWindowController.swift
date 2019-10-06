//
//  DetailWindowController.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 29.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

class CoverWindowController<RootView : View>: NSWindowController {
    convenience init(rootView: RootView) {
        let hostingController = NSHostingController(rootView: rootView.frame(width: 640, height: 640))
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 640, height: 640))
		window.center()
        self.init(window: window)
    }
}
