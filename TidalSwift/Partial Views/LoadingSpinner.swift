//
//  LoadingSpinner.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct FullscreenLoadingSpinner: View {
	let externalState: LoadingState?
	
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
	let externalState: LoadingState?
	var loadingState: LoadingState {
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
	
	@EnvironmentObject var viewState: ViewState
	
	@State var animate = false
	
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
				Image(systemName: "wifi.exclamationmark")
					.resizable()
					.scaledToFit()
					.toolTip("Your connection appears to be offline")
					.onTapGesture {
						viewState.refreshCurrentView()
					}
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
struct LoadingSpinner_Previews: PreviewProvider {
	static var previews: some View {
		FullscreenLoadingSpinner()
	}
}
#endif
