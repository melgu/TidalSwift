//
//  Tools.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import MCP
import TidalSwiftLib

// The tools of `tidal mcp`, each backed by the same operation as the matching command

private let readOnly = Tool.Annotations(readOnlyHint: true)
/// Clients assume tools are destructive unless told otherwise
private let additive = Tool.Annotations(readOnlyHint: false, destructiveHint: false)
private let destructive = Tool.Annotations(readOnlyHint: false, destructiveHint: true)

let tools: [Tool] = [
	Tool(
		name: "account",
		title: "Account",
		description: "The logged in Tidal account: user name, country and subscription.",
		inputSchema: schema([:]),
		annotations: readOnly
	),
	Tool(
		name: "search",
		title: "Search",
		description: "Search Tidal for tracks, albums, artists, playlists and videos.",
		inputSchema: schema([
			"query": string("What to search for"),
			"types": array(kindProperty("Only return these types. Defaults to all.")),
			"limit": integer("Maximum results per type. Defaults to 10.")
		], required: ["query"]),
		annotations: readOnly
	),
	Tool(
		name: "list_playlists",
		title: "List Playlists",
		description: "The account's own playlists and the ones it added to its favorites. Only own playlists (isOwn) can be changed.",
		inputSchema: schema([
			"own_only": boolean("Only list the account's own playlists")
		]),
		annotations: readOnly
	),
	Tool(
		name: "show_playlist",
		title: "Show Playlist",
		description: "A playlist and its tracks, with the positions remove_from_playlist and move_in_playlist take.",
		inputSchema: schema([
			"playlist": string(playlistDescription)
		], required: ["playlist"]),
		annotations: readOnly
	),
	Tool(
		name: "create_playlist",
		title: "Create Playlist",
		description: "Create an empty playlist.",
		inputSchema: schema([
			"title": string("The title"),
			"description": string("The description")
		], required: ["title"]),
		annotations: additive
	),
	Tool(
		name: "edit_playlist",
		title: "Edit Playlist",
		description: "Change the title or description of one of the account's playlists. What isn't given stays as it is.",
		inputSchema: schema([
			"playlist": string(playlistDescription),
			"title": string("The new title"),
			"description": string("The new description. An empty string removes it.")
		], required: ["playlist"]),
		annotations: additive
	),
	Tool(
		name: "delete_playlist",
		title: "Delete Playlist",
		description: "Delete one of the account's playlists. This can't be undone.",
		inputSchema: schema([
			"playlist": string(playlistDescription)
		], required: ["playlist"]),
		annotations: destructive
	),
	Tool(
		name: "add_to_playlist",
		title: "Add to Playlist",
		description: "Add tracks to one of the account's playlists. Albums and playlists add all their tracks. Tracks in the playlist already are skipped and listed as such.",
		inputSchema: schema([
			"playlist": string(playlistDescription),
			"items": array(string("A track, album or playlist")),
			"type": kindProperty(typeDescription),
			"allow_duplicates": boolean("Add tracks that are in the playlist already")
		], required: ["playlist", "items"]),
		annotations: additive
	),
	Tool(
		name: "remove_from_playlist",
		title: "Remove from Playlist",
		description: "Remove items from one of the account's playlists by their position, as show_playlist lists them.",
		inputSchema: schema([
			"playlist": string(playlistDescription),
			"positions": array(integer("A position, starting at 1"))
		], required: ["playlist", "positions"]),
		annotations: destructive
	),
	Tool(
		name: "move_in_playlist",
		title: "Move in Playlist",
		description: "Move an item within one of the account's playlists, by positions as show_playlist lists them.",
		inputSchema: schema([
			"playlist": string(playlistDescription),
			"from": integer("Current position, starting at 1"),
			"to": integer("New position, starting at 1")
		], required: ["playlist", "from", "to"]),
		annotations: additive
	),
	Tool(
		name: "list_favorites",
		title: "List Favorites",
		description: "The account's favorite tracks, albums, artists, playlists or videos.",
		inputSchema: schema([
			"type": kindProperty("What to list")
		], required: ["type"]),
		annotations: readOnly
	),
	Tool(
		name: "add_favorites",
		title: "Add Favorites",
		description: "Add items to the favorites.",
		inputSchema: schema([
			"items": array(string(itemDescription)),
			"type": kindProperty(typeDescription)
		], required: ["items"]),
		annotations: Tool.Annotations(readOnlyHint: false, destructiveHint: false, idempotentHint: true)
	),
	Tool(
		name: "remove_favorites",
		title: "Remove Favorites",
		description: "Remove items from the favorites.",
		inputSchema: schema([
			"items": array(string(itemDescription)),
			"type": kindProperty(typeDescription)
		], required: ["items"]),
		annotations: Tool.Annotations(readOnlyHint: false, destructiveHint: true, idempotentHint: true)
	),
	Tool(
		name: "download",
		title: "Download",
		description: """
			Download a track, album, artist, playlist or video to a folder on this Mac. \
			Tracks come as FLAC (16 bit, 44.1 kHz), as Tidal only offers the lossy and Hi-Res qualities encrypted. \
			Albums and playlists get a folder of their own, artists one per album. Existing files are replaced.
			""",
		inputSchema: schema([
			"item": string(itemDescription),
			"type": kindProperty(typeDescription),
			"atmos": boolean("Download Dolby Atmos instead of stereo where available"),
			"folder": string("Folder to download into, may start with ~. Defaults to ~/Downloads.")
		], required: ["item"]),
		annotations: additive
	)
]

/// Runs a tool and returns its result as text, mostly the JSON `--json` prints
@MainActor
func callTool(_ name: String, arguments: ToolArguments, session: Session, progress: @escaping (String) -> Void) async throws -> String {
	switch name {
	case "account":
		return try jsonString(await account(session: session))
	case "search":
		let kinds = try arguments.kinds("types").map(Set.init) ?? Set(ItemKind.allCases)
		let limit = try arguments.optionalInt("limit") ?? 10
		return try jsonString(await search(session: session, term: arguments.string("query"), kinds: kinds, limit: limit))
	case "list_playlists":
		return try jsonString(await playlists(session: session, ownOnly: arguments.bool("own_only")))
	case "show_playlist":
		return try jsonString(await playlistDetails(session: session, reference: arguments.string("playlist")))
	case "create_playlist":
		let description = try arguments.optionalString("description") ?? ""
		return try jsonString(await createPlaylist(session: session, title: arguments.string("title"), description: description))
	case "edit_playlist":
		let title = try arguments.optionalString("title")
		let description = try arguments.optionalString("description")
		guard title != nil || description != nil else {
			throw CLIError("Pass title, description or both")
		}
		return try jsonString(await editPlaylist(session: session, reference: arguments.string("playlist"), title: title, description: description))
	case "delete_playlist":
		return try jsonString(await deletePlaylist(session: session, reference: arguments.string("playlist")))
	case "add_to_playlist":
		return try jsonString(await addToPlaylist(
			session: session,
			reference: arguments.string("playlist"),
			items: arguments.strings("items"),
			kind: arguments.kind("type"),
			allowDuplicates: arguments.bool("allow_duplicates")
		))
	case "remove_from_playlist":
		return try jsonString(await removeFromPlaylist(session: session, reference: arguments.string("playlist"), positions: arguments.ints("positions")))
	case "move_in_playlist":
		return try jsonString(await moveInPlaylist(session: session, reference: arguments.string("playlist"), from: arguments.int("from"), to: arguments.int("to")))
	case "list_favorites":
		guard let kind = try arguments.kind("type") else {
			throw CLIError("Missing argument type")
		}
		return try jsonString(await favorites(session: session, kind: kind))
	case "add_favorites", "remove_favorites":
		let isFavorite = name == "add_favorites"
		let kind = try arguments.kind("type")
		// Resolved first, so a typo doesn't leave the favorites half changed
		let links = try arguments.strings("items").map { try TidalLink(reference: $0, kind: kind) }
		for link in links {
			try await changeFavorite(session: session, link: link, isFavorite: isFavorite)
		}
		return "\(isFavorite ? "Added" : "Removed") \(links.count == 1 ? "1 item" : "\(links.count) items")"
	case "download":
		let link = try TidalLink(reference: arguments.string("item"), kind: arguments.kind("type"))
		let destination = try downloadFolder(path: arguments.optionalString("folder"), fallback: .downloadsDirectory)
		let options = DownloadOptions(audioQuality: .high, preferDolbyAtmos: try arguments.bool("atmos"), destination: destination)
		return try jsonString(await download(session: session, link: link, options: options, progress: progress))
	default:
		throw MCPError.invalidParams("Unknown tool \(name)")
	}
}

private let playlistDescription = "A playlist link or UUID"
private let itemDescription = "A Tidal link, playlist UUID or ID"
private let typeDescription = "What bare IDs are. Not needed for links and UUIDs."

private func schema(_ properties: [String: Value], required: [String] = []) -> Value {
	.object([
		"type": "object",
		"properties": .object(properties),
		"required": .array(required.map { .string($0) })
	])
}

private func string(_ description: String) -> Value {
	.object(["type": "string", "description": .string(description)])
}

private func integer(_ description: String) -> Value {
	.object(["type": "integer", "description": .string(description)])
}

private func boolean(_ description: String) -> Value {
	.object(["type": "boolean", "description": .string(description)])
}

private func array(_ items: Value) -> Value {
	.object(["type": "array", "items": items])
}

private func kindProperty(_ description: String) -> Value {
	.object([
		"type": "string",
		"enum": .array(ItemKind.allCases.map { .string($0.rawValue) }),
		"description": .string(description)
	])
}
