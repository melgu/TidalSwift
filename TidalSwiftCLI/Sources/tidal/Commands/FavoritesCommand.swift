//
//  FavoritesCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation
import TidalSwiftLib

struct Favorites: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "List, add and remove favorites.",
		subcommands: [
			List.self,
			Add.self,
			Remove.self
		]
	)
	
	struct List: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "List favorites of one type, newest first."
		)
		
		@Argument(help: "track, album, artist, playlist or video.")
		var type: ItemKind
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let results = try await favorites(session: session, kind: type)
			if output.json {
				try printJSON(results)
			} else {
				results.printLines()
			}
		}
	}
	
	struct Add: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Add items to the favorites."
		)
		
		@OptionGroup var items: FavoriteItems
		
		@MainActor
		func run() async throws {
			try await items.setFavorite(true)
		}
	}
	
	struct Remove: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Remove items from the favorites."
		)
		
		@OptionGroup var items: FavoriteItems
		
		@MainActor
		func run() async throws {
			try await items.setFavorite(false)
		}
	}
}

struct FavoriteItems: ParsableArguments {
	@Argument(help: "Links, playlist UUIDs or IDs.")
	var items: [String]
	
	@Option(name: [.customLong("type"), .short], help: "What the IDs are, if not links.")
	var type: ItemKind?
	
	/// Resolves all items first, so a typo doesn't leave the favorites half changed
	@MainActor
	func setFavorite(_ isFavorite: Bool) async throws {
		let session = try loggedInSession()
		let links = try items.map { try TidalLink(reference: $0, kind: type) }
		for (item, link) in zip(items, links) {
			try await changeFavorite(session: session, link: link, isFavorite: isFavorite)
			print("\(isFavorite ? "Added" : "Removed") \(link.kind.rawValue) \(item)")
		}
	}
}
