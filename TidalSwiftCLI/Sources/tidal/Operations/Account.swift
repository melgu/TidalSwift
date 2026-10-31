//
//  Account.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct Account: Codable {
	struct Subscription: Codable {
		let type: String
		let status: String
		let highestSoundQuality: String
		let validUntil: Date
	}
	
	let userId: Int
	let username: String
	/// Nil if the account has no name set
	let name: String?
	let email: String
	let countryCode: String
	/// Nil if it couldn't be loaded, which doesn't make the account itself unusable
	let subscription: Subscription?
}

@MainActor
func account(session: Session) async throws -> Account {
	guard let userId = session.userId,
		  let user = await session.user(userId: userId)
	else {
		throw CLIError("Couldn't load the account")
	}
	
	let subscription = await session.subscriptionInfo().map {
		Account.Subscription(
			type: $0.subscription.type,
			status: $0.status,
			highestSoundQuality: $0.highestSoundQuality,
			validUntil: $0.validUntil
		)
	}
	
	let name = [user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ")
	return Account(
		userId: user.id,
		username: user.username,
		name: name.isEmpty ? nil : name,
		email: user.email,
		countryCode: user.countryCode,
		subscription: subscription
	)
}
