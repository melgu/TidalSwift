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
	@State var credits: [Credit]?
	
	@State var loadingState: LoadingState = .loading
	
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
						Text("\(credit.contributors.formContributorString())\n")
					}
					Spacer(minLength: 0)
				} else if loadingState == .loading {
					FullscreenLoadingSpinner(.loading)
				} else {
					Text("No Credits available")
						.foregroundColor(.secondary)
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
