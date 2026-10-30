//
//  CreditsView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct CreditsView: View {
	let session: Session
	@State var track: Track?
	@State var album: Album?
	@State private var credits: [Credit]?
	
	@State private var loadingState: LoadingState = .loading
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Credits")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				if let credits = credits, !credits.isEmpty {
					ForEach(credits) { credit in
						Text(credit.type)
							.bold()
						FlowLayout {
							ForEach(Array(credit.contributors.enumerated()), id: \.offset) { i, contributor in
								HStack(spacing: 0) {
									ContributorLink(contributor: contributor)
									if i < credit.contributors.count - 1 {
										Text(i == credit.contributors.count - 2 ? " & " : ", ")
									}
								}
							}
						}
						.padding(.bottom)
					}
					Spacer(minLength: 0)
				} else if loadingState == .loading {
					FullscreenLoadingSpinner(.loading)
				} else {
					Text("No Credits available")
						.foregroundStyle(.secondary)
					Spacer(minLength: 0)
				}
			}
			.padding()
		}
		.task {
			var t: [Credit]?
			if let track {
				t = await track.getCredits(session: session)
			} else if let album {
				t = await album.credits(session: session)
			}
			
			if let t {
				credits = t
				loadingState = .successful
			} else {
				loadingState = .error
			}
		}
	}
}

/// A contributor's name, linking to their artist view if they have an ID
private struct ContributorLink: View {
	let contributor: Contributor
	
	@Environment(ViewState.self) private var viewState
	
	var body: some View {
		if let id = contributor.id {
			Button(contributor.name) {
				viewState.open(.artist(id: id))
				#if canImport(AppKit)
				viewState.window?.makeKeyAndOrderFront(nil)
				#endif
			}
			.buttonStyle(.hoverLink)
		} else {
			Text(contributor.name)
		}
	}
}
