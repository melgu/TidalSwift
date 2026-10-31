//
//  SearchCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation

struct Search: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Search for tracks, albums, artists, playlists and videos."
	)
	
	@Argument(help: "What to search for.")
	var terms: [String]
	
	@Option(name: [.customLong("type"), .short], help: "Only search for these. Can be repeated.")
	var types: [ItemKind] = []
	
	@Option(help: "Maximum number of results per type.")
	var limit = 10
	
	@OptionGroup var output: OutputOptions
	
	@MainActor
	func run() async throws {
		let session = try loggedInSession()
		let kinds = types.isEmpty ? Set(ItemKind.allCases) : Set(types)
		let results = try await search(session: session, term: terms.joined(separator: " "), kinds: kinds, limit: limit)
		if output.json {
			try printJSON(results)
		} else {
			results.printLines()
		}
	}
}
