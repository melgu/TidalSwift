//
//  PlayerView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import AVKit

struct PlayerView: NSViewRepresentable {
	func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<PlayerView>) {
		
	}
	func makeNSView(context: Context) -> NSView {
		return PlayerNSView(frame: .zero)
	}
}

class PlayerNSView: NSView{
	private let playerLayer = AVPlayerLayer()
	
	override init(frame: CGRect){
		super.init(frame: frame)
//		let urlVideo = URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!
		let urlVideo = URL(string: "http://api.tidal.com/v1/videos/98785108/hls/CAEQARgDIB8onxA=.m3u8?authtoken=exp~1566425270000.hmac~s-qcr5zT9d-h4lsKFGFzeZtPweknicoaO8tsMJZP4kM=")!
		let player = AVPlayer(url: urlVideo)
		player.play()
		playerLayer.player = player
		if layer == nil{
			layer = CALayer()
		}
		layer?.addSublayer(playerLayer)
	}
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func layout() {
		super.layout()
		playerLayer.frame = bounds
	}
}

//struct PlayerView: NSViewRepresentable {
//
//	var avPlayer: AVPlayer
//
//	func makeNSView(context: Context) -> AVPlayerView {
//		let view = AVPlayerView()
//		view.player = avPlayer
//		return view
//	}
//
//	func updateNSView(_ view: AVPlayerView, context: Context) {
////		let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
////		let region = MKCoordinateRegion(center: coordinate, span: span)
////		view.setRegion(region, animated: true)
//	}
//}

struct PlayerView_Previews: PreviewProvider {
	
	static var previews: some View {
		PlayerView()
	}
}
