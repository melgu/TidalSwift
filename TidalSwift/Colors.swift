//
//  Colors.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

// MARK: Global Constants

let CORNERRADIUS: CGFloat = 3
let SHADOWRADIUS: CGFloat = 3
let SHADOWY: CGFloat = 3


// MARK: - Playback Progress Bar

extension Color {
	static func playbackProgressBarForeground(for colorScheme: ColorScheme) -> Color {
		if colorScheme == .light {
			return .black
		} else {
			return .white
		}
	}
	
	static func playbackProgressBarBackground(for colorScheme: ColorScheme) -> Color {
		if colorScheme == .light {
			return .secondary
		} else {
			return .secondary
		}
	}
}


// MARK: - SF Symbols: Colorizing Images

extension View {
	func primaryIconColor() -> some View {
		self.modifier(PrimaryIconColor())
	}
	func secondaryIconColor() -> some View {
		self.modifier(SecondaryIconColor())
	}
}

struct PrimaryIconColor: ViewModifier {
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	func body(content: Content) -> some View {
		Group {
			if colorScheme == .light {
				content
			} else {
				content
					.colorInvert()
			}
		}
	}
}

struct SecondaryIconColor: ViewModifier {
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	func body(content: Content) -> some View {
		Group {
			if colorScheme == .light {
				content
					.opacity(0.5)
			} else {
				content
					.colorInvert()
					.opacity(0.5)
			}
		}
	}
}

extension NSImage {
	func tint(color: NSColor) -> NSImage {
		let image = self.copy() as! NSImage
		image.lockFocus()
		
		color.set()
		
		let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
		imageRect.fill(using: .sourceAtop)
		
		image.unlockFocus()
		
		return image
	}
}
