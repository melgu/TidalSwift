//
//  MixGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct MixGrid: View {
	let mixes: [MixesItem]
	let session: Session
	let player: Player
	
	var body: some View {
		LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))]) {
			ForEach(mixes) { mix in
				MixGridItem(mix: mix, session: session, player: player)
			}
		}
	}
}
