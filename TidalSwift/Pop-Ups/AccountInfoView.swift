//
//  AccountInfoView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 04.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct AccountInfoView: View {
	let session: Session
	@State var user: User?
	@State var subscription: Subscription?
	
	@State var workItem: DispatchWorkItem?
	@State var loadingState: LoadingState = .loading
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if loadingState == .successful, let user = user, let subscription = subscription {
					HStack {
						VStack {
							Text("User")
								.font(.title)
							if let pictureUrl = user.pictureUrl(session: session, resolution: 210) {
								AsyncImage(url: pictureUrl) { image in
									image.resizable().scaledToFit()
								} placeholder: {
									Rectangle()
								}
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
								.accessibilityHidden(true)
							}
							UserInfoView(user: user, session: session)
							Spacer(minLength: 0)
						}
						.padding()
						Divider()
						VStack {
							Text("Subscription")
								.font(.title)
							SubscriptionInfoView(subscription: subscription)
							Spacer(minLength: 0)
						}
						.padding()
						Spacer(minLength: 0)
					}
				} else if loadingState == .loading {
					FullscreenLoadingSpinner(.loading)
				} else {
					Text("Cannot access user or subscription info")
						.foregroundColor(.secondary)
					Spacer(minLength: 0)
				}
			}
		}
		.onAppear {
			workItem = createWorkItem()
			DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
		}
		.onDisappear {
			workItem?.cancel()
		}
	}
	
	func createWorkItem() -> DispatchWorkItem {
		DispatchWorkItem {
			Task {
				var tUser: User?
				let tSubscription: Subscription?
				
				if let userId = session.userId {
					tUser = await session.user(userId: userId)
				}
				tSubscription = await session.subscriptionInfo()
				
				await MainActor.run {
					if tUser != nil && tSubscription != nil {
						user = tUser
						subscription = tSubscription
						loadingState = .successful
					} else {
						loadingState = .error
					}
				}
			}
		}
	}
}

struct UserInfoView: View {
	let user: User
	let session: Session
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("")
			Group {
				Text("ID")
					.bold()
				Text(String(user.id))
				Text("")
				Text("Username")
					.bold()
				Text(user.username)
				Text("")
				Text("First Name")
					.bold()
				Text(user.firstName)
				Text("")
				
			}
			Group {
				Text("Last Name")
					.bold()
				Text(user.lastName)
				Text("")
				Text("E-Mail")
					.bold()
				Text(user.email)
				Text("")
				Text("Country Code")
					.bold()
				Text(user.countryCode)
				Text("")
			}
			Group {
				Text("Account Created")
					.bold()
				Text(DateFormatter.dateOnly.string(from: user.created))
				Text("")
				Text("Newsletter active")
					.bold()
				Text(user.newsletter ? "Yes" : "No")
				Text("")
				Text("EULA accepted")
					.bold()
				Text(user.acceptedEULA ? "Yes" : "No")
				Text("")
				
			}
			Group {
				Text("Gender")
					.bold()
				Text(user.gender)
				Text("")
				Text("Date of Birth")
					.bold()
				Text(DateFormatter.dateOnly.string(from: user.dateOfBirth))
				
				if let faceBookUid = user.facebookUid {
					Text("")
					Text("Facebook User ID")
						.bold()
					Text(String(faceBookUid))
				}
			}
		}
	}
}

struct SubscriptionInfoView: View {
	let subscription: Subscription
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("")
			Group {
				Text("Valid until")
					.bold()
				Text(DateFormatter.dateOnly.string(from: subscription.validUntil))
				Text("")
				Text("Status")
					.bold()
				Text(subscription.status)
				Text("")
				
			}
			Group {
				Text("Subscription Type")
					.bold()
				Text(subscription.subscription.type)
				Text("")
				Text("Offline Grace Period")
					.bold()
				Text("\(subscription.subscription.offlineGracePeriod)")
				Text("")
			}
			Group {
				Text("Highest possible Audio Quality")
					.bold()
				Text("\(subscription.highestSoundQuality.rawValue)")
				Text("")
				Text("Premium Access")
					.bold()
				Text(subscription.premiumAccess ? "Yes" : "No")
				Text("")
				Text("Can get Trial")
					.bold()
				Text(subscription.canGetTrial ? "Yes" : "No")
				Text("")
			}
			Group {
				Text("Payment Type")
					.bold()
				Text(subscription.paymentType)
			}
		}
	}
}
