//
//  MyMixes.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 27.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct MyMixes: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("My Mixes")
						.font(.largeTitle)
					Spacer()
					LoadingSpinner()
				}
				
				if let mixes = viewState.stack.last?.mixes {
					MixGrid(mixes: mixes, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
