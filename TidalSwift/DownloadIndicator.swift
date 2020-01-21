//
//  DownloadIndicator.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

struct DownloadIndicator: View {
	@State var animationState: Bool = false
	@State var timerCancellable: AnyCancellable?
	
	@EnvironmentObject var downloadStatus: DownloadStatus
	
	var body: some View {
		Group {
			if downloadStatus.downloadingTasks > 0 {
				Text(animationState ? "􀈉" : "􀈈")
					.onAppear {
						self.timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
							.autoconnect()
							.sink { _ in
								self.animationState.toggle()
						}
				}
				.toolTip("Downloads currently running")
				.onDisappear {
					self.timerCancellable?.cancel()
				}
			}
		}
	}
}

struct DownloadIndicator_Previews: PreviewProvider {
	static var previews: some View {
		DownloadIndicator()
	}
}
