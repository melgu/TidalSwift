//
//  LoadingSpinner.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI

struct LoadingSpinner: View {
	
	var body: some View {
		ZStack {
			Text("􀊯")
				.font(.title)
				.foregroundColor(.white)
//				.rotationEffect(.degrees(360))
//				.animation(.linear(duration: 3))
				.frame(width: 50, height: 50)
				.background(Color(.gray))
		}
	}
}

#if DEBUG
struct LoadingSpinner_Previews: PreviewProvider {
	static var previews: some View {
		LoadingSpinner()
	}
}
#endif
