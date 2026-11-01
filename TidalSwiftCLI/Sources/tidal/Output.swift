//
//  Output.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation

/// Fails the command with a message on stderr and a nonzero exit code
struct CLIError: Error, CustomStringConvertible {
	let description: String
	
	init(_ description: String) {
		self.description = description
	}
}

/// For progress and hints, so stdout only carries results
func printToStderr(_ message: String) {
	FileHandle.standardError.write(Data((message + "\n").utf8))
}

func printJSON<Value: Encodable>(_ value: Value) throws {
	print(try jsonString(value))
}

/// The JSON that `--json` prints and MCP tools return
func jsonString<Value: Encodable>(_ value: Value) throws -> String {
	let encoder = JSONEncoder()
	encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
	encoder.dateEncodingStrategy = .iso8601
	return String(decoding: try encoder.encode(value), as: UTF8.self)
}
