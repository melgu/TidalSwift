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
					Image("chevron.left")
						.primaryIconColor()
				}
				.padding(.leading, 10)
				Spacer(minLength: 0)
				LoadingSpinner()
			}
			.frame(height: 40)
			Spacer(minLength: 0)
		}
	}
}
