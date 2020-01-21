//
//  Tooltips.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.01.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

public extension View {
	/// Overlays this view with a view that provides a toolTip with the given string.
	func toolTip(_ toolTip: String?) -> some View {
		self.overlay(ToolTipView(toolTip))
	}
}

private struct ToolTipView: NSViewRepresentable {
	typealias NSViewType = NSView
	
	let toolTip: String?
	
	init(_ toolTip: String?) {
		self.toolTip = toolTip
	}
	
	func makeNSView(context: NSViewRepresentableContext<ToolTipView>) -> NSView {
		let view = NSView()
		return view
	}
	
	func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<ToolTipView>) {
		nsView.toolTip = self.toolTip
	}
	
	
}
