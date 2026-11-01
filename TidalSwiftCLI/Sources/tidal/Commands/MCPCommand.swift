//
//  MCPCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser

struct MCPCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "mcp",
		abstract: "Run an MCP server on stdin and stdout, for AI assistants.",
		discussion: """
			Offers search, playlists, favorites and downloads as tools. If you aren't logged in, \
			the first tool call answers with a login link. Register it with your MCP client, e.g. \
			for every folder in Claude Code (options go before --, the rest is the command to run):
			claude mcp add -s user tidal -- tidal mcp
			"""
	)
	
	@MainActor
	func run() async throws {
		try await TidalServer().run()
	}
}
