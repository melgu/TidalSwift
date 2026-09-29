//
//  BackButton.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct BackButton: View {
	@Environment(ViewState.self) var viewState
	
	var body: some View {
		VStack {
			HStack {
				Button {
					print("Back")
					viewState.pop()
				} label: {
					Image(systemName: "chevron.left")
				}
				Spacer(minLength: 0)
				LoadingSpinner()
			}
			.padding(.horizontal)
			.frame(height: 40)
			Spacer(minLength: 0)
		}
	}
}
