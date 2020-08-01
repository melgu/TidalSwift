//
//  MixGrid.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import Grid

struct MixGrid: View {
	let mixes: [MixesItem]
	let session: Session
	let player: Player
	
	var body: some View {
		Grid(mixes) { mix in
			MixGridItem(mix: mix, session: session, player: player)
		}
		.gridStyle(
			ModularGridStyle(.vertical, columns: .min(170), rows: .fixed(210), spacing: 10)
		)
	}
}
