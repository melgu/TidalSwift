//
//  Login.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation
import TidalSwiftLib

struct Login: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Log in by approving this device in the browser."
	)
	
	@MainActor
	func run() async throws {
		let session = makeSession()
		for await state in session.startAuthorization() {
			switch state {
			case .waiting:
				break
			case .pending(let loginUrl, let expiration):
				printToStderr("Open this link and approve the login:\n\(loginUrl.absoluteString)")
				printToStderr("Waiting until \(expiration.formatted(date: .omitted, time: .shortened)) …")
			case .success:
				session.saveConfig()
				let account = try await account(session: session)
				print("Logged in as \(account.username)")
			case .failure(let error):
				throw CLIError("Login failed: \(error.localizedDescription)")
			}
		}
	}
}

struct Logout: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Remove the stored login."
	)
	
	@MainActor
	func run() async throws {
		makeSession().logout()
		print("Logged out")
	}
}
