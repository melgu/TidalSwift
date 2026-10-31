//
//  Tidal.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser

@main
struct Tidal: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "tidal",
		abstract: "Manage your Tidal playlists and favorites, search, and download.",
		subcommands: [
			Login.self,
			Logout.self,
			Me.self,
			Search.self,
			Playlists.self,
			Favorites.self,
			DownloadCommand.self
		]
	)
}

/// Options every command that prints results takes
struct OutputOptions: ParsableArguments {
	@Flag(help: "Print JSON instead of text.")
	var json = false
}
