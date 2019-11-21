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
	let credits: [Credit]?
	
	init(track: Track, session: Session) {
		self.credits = track.getCredits(session: session)
	}
	
	init(album: Album, session: Session) {
		self.credits = album.getCredits(session: session)
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				HStack {
					Text("Credits")
						.font(.title)
						.padding(.bottom)
					Spacer(minLength: 0)
				}
				if credits == nil || credits!.isEmpty {
					Text("No Credits available")
						.foregroundColor(.secondary)
				} else {
					ForEach(credits!) { credit in
						Text(credit.type)
							.bold()
						Text("\(credit.contributors.formContributorString())\n")
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}
