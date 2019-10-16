//
//  Colors.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 06.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

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

let CORNERRADIUS: CGFloat = 3
let SHADOWRADIUS: CGFloat = 3
let SHADOWY: CGFloat = 3
