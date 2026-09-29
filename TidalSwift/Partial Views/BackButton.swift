//
//  BackButton.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct BackButton: View {
	@Environment(ViewState.self) private var viewState
	
	var body: some View {
		VStack {
			HStack {
				Button {
					print("Back")
					viewState.pop()
				} label: {
					Image(systemName: "chevron.left")
				}
				.buttonStyle(.backButton)
				Spacer(minLength: 0)
				LoadingSpinner()
			}
			.padding(.horizontal)
			.frame(height: 40)
			Spacer(minLength: 0)
		}
	}
}

private extension PrimitiveButtonStyle where Self == BackButtonStyle {
	static var backButton: BackButtonStyle { .init() }
}

private struct BackButtonStyle: PrimitiveButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		if #available(anyAppleOS 26.0, *) {
			Button(configuration).buttonStyle(.glass)
		} else {
			Button(configuration).buttonStyle(.automatic)
		}
	}
}
