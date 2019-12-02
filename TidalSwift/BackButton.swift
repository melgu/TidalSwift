//
//  BackButton.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct BackButton: View {
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			HStack {
				Button(action: {
					print("Back")
					self.viewState.pop()
				}) {
					Text("􀆉")
				}
				.padding(.leading, 10)
				Spacer(minLength: 0)
				LoadingSpinner()
					.shadow(color: .secondary, radius: SHADOWRADIUS)
			}
			.frame(height: 40)
			Spacer(minLength: 0)
		}
	}
}
