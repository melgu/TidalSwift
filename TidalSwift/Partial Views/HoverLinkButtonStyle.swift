//
//  HoverLinkButtonStyle.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import SwiftUI

extension ButtonStyle where Self == HoverLinkButtonStyle {
	/// Looks like a text link, underlined on hover
	static var hoverLink: HoverLinkButtonStyle { .init() }
}

struct HoverLinkButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		HoverLinkLabel(configuration: configuration)
	}
}

private struct HoverLinkLabel: View {
	let configuration: ButtonStyleConfiguration
	
	@State private var isHovered = false
	
	var body: some View {
		configuration.label
			.foregroundStyle(.link)
			.underline(isHovered)
			.opacity(configuration.isPressed ? 0.7 : 1)
			.contentShape(Rectangle())
			.onHover { hovering in
				isHovered = hovering
				#if canImport(AppKit)
				if hovering {
					NSCursor.pointingHand.push()
				} else {
					NSCursor.pop()
				}
				#endif
			}
	}
}
