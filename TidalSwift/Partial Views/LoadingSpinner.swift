//
//  LoadingSpinner.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct FullscreenLoadingSpinner: View {
	private let externalState: LoadingState?
	
	init(_ externalState: LoadingState? = nil) {
		self.externalState = externalState
	}
	
	var body: some View {
		VStack {
			Spacer(minLength: 0)
			HStack {
				Spacer(minLength: 0)
				LoadingSpinner(externalState)
				Spacer(minLength: 0)
			}
			Spacer(minLength: 0)
		}
	}
}

struct LoadingSpinner: View {
	private let externalState: LoadingState?
	private var loadingState: LoadingState {
		if let state = externalState {
			return state
		} else {
			if let view = viewState.stack.last {
				return view.loadingState
			} else {
				return .loading
			}
		}
	}
	
	init(_ externalState: LoadingState? = nil) {
		self.externalState = externalState
	}
	
	@Environment(ViewState.self) private var viewState
	
	@State private var animate = false
	
	var body: some View {
		Group {
			if loadingState == .loading {
				Image(systemName: "arrow.2.circlepath")
					.resizable()
					.scaledToFit()
					.rotationEffect(animate ? .degrees(360) : .degrees(0))
					.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animate)
					.onAppear {
						animate.toggle()
					}
			} else if loadingState == .error {
				Button {
					viewState.refreshCurrentView()
				} label: {
					Image(systemName: "wifi.exclamationmark")
						.resizable()
						.scaledToFit()
						.accessibilityLabel("Retry")
						.help("Your connection appears to be offline")
				}
				.buttonStyle(.plain)
			}
		}
		.frame(width: 30, height: 30)
	}
}

enum LoadingState: Int, Codable {
	case loading
	case successful
	case error
}

#if DEBUG
private struct LoadingSpinner_Previews: PreviewProvider {
	static var previews: some View {
		FullscreenLoadingSpinner()
	}
}
#endif
