//
//  DownloadIndicator.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct DownloadIndicator: View {
	@State var animationState: Bool = false
	
	@Environment(DownloadStatus.self) var downloadStatus
	
	var body: some View {
		Group {
			if downloadStatus.downloadingTasks > 0 {
				Text(animationState ? "􀈉" : "􀈈")
					.task {
						while true {
							do {
								try await Task.sleep(for: .seconds(1))
							} catch {
								return
							}
							animationState.toggle()
						}
					}
					.help("Downloads currently running")
			}
		}
	}
}

struct DownloadIndicator_Previews: PreviewProvider {
	static var previews: some View {
		DownloadIndicator()
	}
}
