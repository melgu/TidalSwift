//
//  Session.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

/// Kept apart from the app's login, as the two can't share a Keychain item without prompts
private let keychainService = "de.melgu.TidalSwift.cli"

@MainActor
func makeSession() -> Session {
	Session(config: nil, keychainService: keychainService)
}

/// A session with the stored login, or an error asking to log in
@MainActor
func loggedInSession() throws -> Session {
	let session = makeSession()
	guard session.loadSession() else {
		throw CLIError("Not logged in. Run `tidal login` first.")
	}
	return session
}
