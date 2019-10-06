//
//  PlaybackInfo.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

final class PlaybackInfo: ObservableObject {
	@Published var currentIndex = 0
	@Published var fraction: CGFloat = 0.0
	@Published var playing: Bool = false
}
