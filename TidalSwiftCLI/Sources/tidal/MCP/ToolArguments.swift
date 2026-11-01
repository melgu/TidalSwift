//
//  ToolArguments.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import MCP

/// The arguments of a tool call, read with errors the model can act on
struct ToolArguments {
	let values: [String: Value]
	
	init(_ values: [String: Value]?) {
		self.values = values ?? [:]
	}
	
	func string(_ name: String) throws -> String {
		guard let value = try optionalString(name) else {
			throw CLIError("Missing argument \(name)")
		}
		return value
	}
	
	func optionalString(_ name: String) throws -> String? {
		guard let value = present(name) else { return nil }
		guard let string = value.stringValue else {
			throw CLIError("\(name) must be a string")
		}
		return string
	}
	
	func int(_ name: String) throws -> Int {
		guard let value = try optionalInt(name) else {
			throw CLIError("Missing argument \(name)")
		}
		return value
	}
	
	func optionalInt(_ name: String) throws -> Int? {
		guard let value = present(name) else { return nil }
		// Some clients send whole numbers as doubles
		if let int = value.intValue ?? value.doubleValue.flatMap({ Int(exactly: $0) }) {
			return int
		}
		throw CLIError("\(name) must be a whole number")
	}
	
	func bool(_ name: String) throws -> Bool {
		guard let value = present(name) else { return false }
		guard let bool = value.boolValue else {
			throw CLIError("\(name) must be true or false")
		}
		return bool
	}
	
	func strings(_ name: String) throws -> [String] {
		guard let value = present(name) else {
			throw CLIError("Missing argument \(name)")
		}
		// A single item is accepted for convenience
		if let string = value.stringValue {
			return [string]
		}
		guard let strings = value.arrayValue?.map({ $0.stringValue ?? $0.intValue.map(String.init) }),
			  !strings.contains(nil)
		else {
			throw CLIError("\(name) must be a list of strings")
		}
		return strings.compactMap { $0 }
	}
	
	func ints(_ name: String) throws -> [Int] {
		guard let value = present(name) else {
			throw CLIError("Missing argument \(name)")
		}
		guard let ints = value.arrayValue?.map({ $0.intValue ?? $0.doubleValue.flatMap { Int(exactly: $0) } }),
			  !ints.contains(nil)
		else {
			throw CLIError("\(name) must be a list of whole numbers")
		}
		return ints.compactMap { $0 }
	}
	
	func kind(_ name: String) throws -> ItemKind? {
		guard let string = try optionalString(name) else { return nil }
		guard let kind = ItemKind(rawValue: string) else {
			throw CLIError("\(name) must be one of \(ItemKind.allCases.map(\.rawValue).joined(separator: ", "))")
		}
		return kind
	}
	
	func kinds(_ name: String) throws -> [ItemKind]? {
		guard present(name) != nil else { return nil }
		return try strings(name).map { string in
			guard let kind = ItemKind(rawValue: string) else {
				throw CLIError("\(name) may only contain \(ItemKind.allCases.map(\.rawValue).joined(separator: ", "))")
			}
			return kind
		}
	}
	
	/// Null counts as missing, as some clients send it for omitted optional arguments
	private func present(_ name: String) -> Value? {
		guard let value = values[name], !value.isNull else { return nil }
		return value
	}
}
