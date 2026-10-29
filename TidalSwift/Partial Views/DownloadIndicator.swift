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
	@State private var animationState: Bool = false
	
	@Environment(DownloadStatus.self) private var downloadStatus
	
	var body: some View {
		Group {
			if !downloadStatus.tasks.isEmpty {
				Image(systemName: animationState ? "square.and.arrow.down.on.square.fill" : "square.and.arrow.down.on.square")
					.accessibilityLabel("Downloads")
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
					.help(helpText)
			}
		}
	}
	
	private var helpText: String {
		let lines = downloadStatus.tasks.map { task in
			let steps = [
				task.album.map { "Album \(describe($0))" },
				task.track.map { "Track \(describe($0))" },
				task.video.map { "Video \(describe($0))" },
				task.progress.map { $0.formatted(.percent.precision(.fractionLength(0))) },
			]
				.compactMap { $0 }
			return steps.isEmpty ? task.title : "\(task.title): \(steps.joined(separator: ", "))"
		}
		return (["Downloading:"] + lines).joined(separator: "\n")
	}
	
	private func describe(_ step: DownloadTask.Step) -> String {
		"\(step.index) of \(step.count) “\(step.title)”"
	}
}

private struct DownloadIndicator_Previews: PreviewProvider {
	static var previews: some View {
		DownloadIndicator()
	}
}
