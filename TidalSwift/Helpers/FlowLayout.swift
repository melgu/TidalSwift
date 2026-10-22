//
//  FlowLayout.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import SwiftUI

/// Places its subviews next to each other, wrapping to a new line like text when they don't fit
struct FlowLayout: Layout {
	var spacing: CGFloat = 0
	var lineSpacing: CGFloat = 2
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		arrange(subviews, maxWidth: proposal.width ?? .infinity).size
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let frames = arrange(subviews, maxWidth: bounds.width).frames
		for (subview, frame) in zip(subviews, frames) {
			subview.place(
				at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
				proposal: ProposedViewSize(frame.size)
			)
		}
	}
	
	private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> (frames: [CGRect], size: CGSize) {
		var frames: [CGRect] = []
		var x: CGFloat = 0
		var y: CGFloat = 0
		var lineHeight: CGFloat = 0
		var width: CGFloat = 0
		
		for subview in subviews {
			let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
			if x > 0 && x + size.width > maxWidth {
				x = 0
				y += lineHeight + lineSpacing
				lineHeight = 0
			}
			frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
			width = max(width, x + size.width)
			x += size.width + spacing
			lineHeight = max(lineHeight, size.height)
		}
		
		return (frames, CGSize(width: width, height: y + lineHeight))
	}
}
