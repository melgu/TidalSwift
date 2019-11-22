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
	
	@State var workItem: DispatchWorkItem?
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
				if credits != nil && !credits!.isEmpty {
					ForEach(credits!) { credit in
						Text(credit.type)
							.bold()
						Text("\(credit.contributors.formContributorString())\n")
					}
					Spacer(minLength: 0)
				} else if loadingState == .loading {
					LoadingSpinner()
				} else {
					Text("No Credits available")
						.foregroundColor(.secondary)
					Spacer(minLength: 0)
				}
			}
			.padding()
		}
		.onAppear() {
			self.workItem = self.createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: self.workItem!)
		}
		.onDisappear() {
			self.workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		return DispatchWorkItem {
			var t: [Credit]?
			if self.track != nil {
				t = self.track!.getCredits(session: self.session)
			} else if self.album != nil {
				t = self.album!.getCredits(session: self.session)
			}
			
			if t != nil {
				DispatchQueue.main.async {
					self.credits = t
					self.loadingState = .successful
				}
			} else {
				DispatchQueue.main.async {
					self.loadingState = .error
				}
			}
		}
	}
}
