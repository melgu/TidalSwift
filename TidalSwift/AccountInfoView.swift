//
//  AccountInfoView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 04.11.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI

struct AccountInfoView: View {
	let user: User?
	let subscription: Subscription?
	let session: Session
	
	init(session: Session) {
		if let userId = session.userId {
			self.user = session.getUser(userId: userId)
		} else {
			self.user = nil
		}
		self.subscription = session.getSubscriptionInfo()
		self.session = session
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if self.user == nil || self.subscription == nil {
					HStack {
						Text("Cannot access user or subscription info")
							.foregroundColor(.secondary)
						Spacer(minLength: 0)
					}
					Spacer(minLength: 0)
				} else {
					HStack {
						VStack {
							Text("User")
								.font(.title)
							URLImageSourceView(
								self.user!.getPictureUrl(session: self.session, resolution: 210)!,
								isAnimationEnabled: true,
								label: Text(self.user!.username)
							)
								.frame(width: 100, height: 100)
								.cornerRadius(CORNERRADIUS)
								.shadow(radius: SHADOWRADIUS, y: SHADOWY)
							UserInfoView(user: self.user!, session: self.session)
							Spacer(minLength: 0)
						}
						.padding()
						Divider()
						VStack {
							Text("Subscription")
								.font(.title)
							SubscriptionInfoView(subscription: self.subscription!)
							Spacer(minLength: 0)
						}
						.padding()
						Spacer(minLength: 0)
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
				Text("")
				Text("Facebook User ID")
					.bold()
				Text(String(user.facebookUid))
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
