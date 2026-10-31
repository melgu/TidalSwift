//
//  Me.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation

struct Me: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Show the logged-in account."
	)
	
	@OptionGroup var output: OutputOptions
	
	@MainActor
	func run() async throws {
		let session = try loggedInSession()
		let account = try await account(session: session)
		
		if output.json {
			try printJSON(account)
			return
		}
		if let name = account.name {
			print("\(name) (\(account.username))")
		} else {
			print(account.username)
		}
		print("Email:    \(account.email)")
		print("Country:  \(account.countryCode)")
		print("User ID:  \(account.userId)")
		if let subscription = account.subscription {
			print("Plan:     \(subscription.type), \(subscription.status.lowercased()) until \(subscription.validUntil.formatted(date: .abbreviated, time: .omitted))")
			print("Quality:  \(subscription.highestSoundQuality)")
		}
	}
}
