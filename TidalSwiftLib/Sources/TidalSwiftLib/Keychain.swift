//
//  Keychain.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import Security

struct KeychainError: Error, CustomStringConvertible {
	let status: OSStatus
	
	var description: String {
		SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
	}
}

/// Generic password items in the login keychain.
/// Doesn't use the data protection keychain, as that needs a provisioning profile.
enum Keychain {
	private static func baseQuery(service: String, account: String) -> [String: Any] {
		[
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]
	}
	
	/// Returns nil if the item doesn't exist
	static func load(service: String, account: String) throws -> Data? {
		var query = baseQuery(service: service, account: account)
		query[kSecReturnData as String] = true
		query[kSecMatchLimit as String] = kSecMatchLimitOne
		
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound {
			return nil
		}
		guard status == errSecSuccess else {
			throw KeychainError(status: status)
		}
		return result as? Data
	}
	
	static func save(_ data: Data, service: String, account: String) throws {
		let query = baseQuery(service: service, account: account)
		let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
		if status == errSecItemNotFound {
			var item = query
			item[kSecValueData as String] = data
			let addStatus = SecItemAdd(item as CFDictionary, nil)
			guard addStatus == errSecSuccess else {
				throw KeychainError(status: addStatus)
			}
		} else if status != errSecSuccess {
			throw KeychainError(status: status)
		}
	}
	
	static func delete(service: String, account: String) throws {
		let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
		guard status == errSecSuccess || status == errSecItemNotFound else {
			throw KeychainError(status: status)
		}
	}
}
