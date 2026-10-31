//
//  PlaylistsCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation

struct Playlists: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "List, show and edit playlists. Playlists are given as a link or UUID.",
		subcommands: [
			List.self,
			Show.self,
			Create.self,
			Edit.self,
			Delete.self,
			Add.self,
			Remove.self,
			Move.self
		]
	)
	
	struct List: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "List your playlists and the ones in your favorites."
		)
		
		@Flag(help: "Only list your own playlists.")
		var own = false
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let playlists = try await playlists(session: session, ownOnly: own)
			if output.json {
				try printJSON(playlists)
			} else {
				playlists.forEach { print($0.line) }
			}
		}
	}
	
	struct Show: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Show a playlist and its tracks, with the positions remove and move take."
		)
		
		@Argument(help: "The playlist.")
		var playlist: String
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let details = try await playlistDetails(session: session, reference: playlist)
			if output.json {
				try printJSON(details)
				return
			}
			print(details.playlist.title)
			if let description = details.playlist.description {
				print(description)
			}
			print(details.playlist.url.absoluteString)
			print()
			let width = String(details.items.count).count
			for item in details.items {
				let position = String(repeating: " ", count: width - String(item.position).count) + String(item.position)
				print("\(position)  \(item.track.line)")
			}
		}
	}
	
	struct Create: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Create a playlist."
		)
		
		@Argument(help: "The title.")
		var title: String
		
		@Option(help: "The description.")
		var description = ""
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let playlist = try await createPlaylist(session: session, title: title, description: description)
			if output.json {
				try printJSON(playlist)
			} else {
				print("Created \(playlist.line)")
			}
		}
	}
	
	struct Edit: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Change the title or description of one of your playlists."
		)
		
		@Argument(help: "The playlist.")
		var playlist: String
		
		@Option(help: "The new title.")
		var title: String?
		
		@Option(help: "The new description. Pass \"\" to remove it.")
		var description: String?
		
		@OptionGroup var output: OutputOptions
		
		func validate() throws {
			if title == nil && description == nil {
				throw ValidationError("Pass --title, --description or both.")
			}
		}
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let edited = try await editPlaylist(session: session, reference: playlist, title: title, description: description)
			if output.json {
				try printJSON(edited)
			} else {
				print("Changed \(edited.line)")
			}
		}
	}
	
	struct Delete: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Delete one of your playlists."
		)
		
		@Argument(help: "The playlist.")
		var playlist: String
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let deleted = try await deletePlaylist(session: session, reference: playlist)
			if output.json {
				try printJSON(deleted)
			} else {
				print("Deleted \(deleted.line)")
			}
		}
	}
	
	struct Add: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Add tracks to one of your playlists. Albums and playlists add all their tracks."
		)
		
		@Argument(help: "The playlist to add to.")
		var playlist: String
		
		@Argument(help: "Tracks, albums or playlists, as links or IDs.")
		var items: [String]
		
		@Option(name: [.customLong("type"), .short], help: "What the IDs are, if not links.")
		var type: ItemKind?
		
		@Flag(help: "Add tracks that are in the playlist already.")
		var allowDuplicates = false
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let addition = try await addToPlaylist(session: session, reference: playlist, items: items, kind: type, allowDuplicates: allowDuplicates)
			if output.json {
				try printJSON(addition)
				return
			}
			if !addition.added.isEmpty {
				print("Added:")
				addition.added.forEach { print($0.line) }
			}
			if !addition.skipped.isEmpty {
				print("Skipped, as they're in the playlist already (pass --allow-duplicates to add them anyway):")
				addition.skipped.forEach { print($0.line) }
			}
		}
	}
	
	struct Remove: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Remove items from one of your playlists by their position, as `show` lists them."
		)
		
		@Argument(help: "The playlist.")
		var playlist: String
		
		@Argument(help: "Positions, starting at 1.")
		var positions: [Int]
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let removed = try await removeFromPlaylist(session: session, reference: playlist, positions: positions)
			if output.json {
				try printJSON(removed)
			} else {
				print("Removed:")
				removed.forEach { print($0.line) }
			}
		}
	}
	
	struct Move: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Move an item within one of your playlists, by positions as `show` lists them."
		)
		
		@Argument(help: "The playlist.")
		var playlist: String
		
		@Argument(help: "Current position, starting at 1.")
		var from: Int
		
		@Argument(help: "New position, starting at 1.")
		var to: Int
		
		@OptionGroup var output: OutputOptions
		
		@MainActor
		func run() async throws {
			let session = try loggedInSession()
			let moved = try await moveInPlaylist(session: session, reference: playlist, from: from, to: to)
			if output.json {
				try printJSON(moved)
			} else {
				print("Moved to position \(to): \(moved.line)")
			}
		}
	}
}
