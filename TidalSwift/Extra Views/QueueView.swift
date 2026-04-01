//
//  QueueView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 05.09.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct QueueView: View {
	unowned let session: Session
	unowned let player: Player
	
	@EnvironmentObject var queueInfo: QueueInfo
    
    @EnvironmentObject var playbackInfo: PlaybackInfo
	func calculateTotalTime(for tracks: [Track]) -> Int {
		var result = 0
		for track in tracks {
			result += track.duration
		}
		return result
	}
	
	var body: some View {
        HStack{
            Text("Queue").font(.largeTitle)
            Button("X",action:{
                player.clearQueue()
            })
        }
       
        List{
            ForEach(queueInfo.queue) { wrappedTrack in
                
                TrackItemView(track: wrappedTrack.track, session: session, player: player, isHovered: false, onHoverChange: {_ in}, onRemovedFromFavorites: {}, onPressedPlay: {
                   
                }, showCover: true, isAlbumView: false)
                
            }
        }
        
	}
}
