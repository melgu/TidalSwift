//
//  ViewHistoryView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 17.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ViewHistoryView: View {
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("View History")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 5)
					VStack {
						Button(action: {
							self.viewState.clearHistory()
						}) {
							Text("Clear")
						}
						Spacer(minLength: 0)
					}
				}
				if viewState.history.isEmpty {
					Text("Empty History")
						.foregroundColor(.secondary)
				} else {
					ForEach(viewState.history) { view in
						ViewHistoryViewRow(view: view)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct ViewHistoryViewRow: View {
	let view: TidalSwiftView
	var text: String
	
	@EnvironmentObject var viewState: ViewState
	
	init(view: TidalSwiftView) {
		self.view = view
		
		text = view.viewType?.rawValue ?? ""
		if view.viewType == .artist {
			text += ": \(view.artist?.name ?? "Missing Artist Name")"
		} else if view.viewType == .album {
			text += ": \(view.album?.title ?? "Missing Album Title")"
		} else if view.viewType == .playlist {
			text += ": \(view.playlist?.title ?? "Missing Playlist Title")"
		} else if view.viewType == .mix {
			text += ": \(view.mix?.title ?? "Missing Mix Title")"
		}
	}
	
	var body: some View {
		Text(text)
			.onTapGesture(count: 2) {
				self.viewState.push(view: self.view)
		}
	}
}

//struct ViewHistoryView_Previews: PreviewProvider {
//	static var previews: some View {
//		ViewHistoryView()
//	}
//}
