//
//  LoadingSpinner.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct LoadingSpinner: View {
	
	@State var animate = false
	
	var body: some View {
		VStack {
			Spacer(minLength: 0)
			HStack {
				Spacer(minLength: 0)
				
				Text("􀊯")
					.font(.title)
					.rotationEffect(animate ? .degrees(360) : .degrees(0))
					.animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
					.onAppear {
						self.animate.toggle()
				}
				
				Spacer(minLength: 0)
			}
			Spacer(minLength: 0)
		}
	}
}

enum LoadingState {
	case loading
	case successful
	case error
}

#if DEBUG
struct LoadingSpinner_Previews: PreviewProvider {
	static var previews: some View {
		LoadingSpinner()
	}
}
#endif
