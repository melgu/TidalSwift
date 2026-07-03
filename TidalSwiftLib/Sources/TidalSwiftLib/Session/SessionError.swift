//
//  SessionError.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 03.07.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

/// Errors thrown by login, token refresh, and other session operations.
public enum SessionError: Error {
	/// No refresh token is stored, so there is nothing to authenticate with.
	case notLoggedIn
	/// Tidal rejected the stored credentials. The user has to log in again.
	case invalidCredentials(description: String?)
	/// The request didn't reach Tidal, e.g. because the device is offline.
	/// The stored credentials may still be valid.
	case network(underlying: Error)
	/// Tidal answered in an unexpected format.
	case unexpectedResponse
}
