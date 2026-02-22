//
//  PlayerView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import AVKit

#if canImport(AppKit)
class VideoPlayerController: NSWindowController {
	convenience init(videoUrl: URL, volume: Float, width: CGFloat = 1280, height: CGFloat = 720) {
		let player = AVPlayer(url: videoUrl)
		player.volume = volume
		player.play()
		
		let playerView = AVPlayerView()
		playerView.player = player
		
		let window = NSWindow(contentRect: NSMakeRect(0, 0, width, height),
							  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
							  backing: NSWindow.BackingStoreType.buffered,
							  defer: false)
		window.contentView = playerView
		window.center()
		self.init(window: window)
	}
}
#endif
