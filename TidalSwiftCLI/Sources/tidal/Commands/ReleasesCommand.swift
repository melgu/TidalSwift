//
//  ReleasesCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation

struct ArtistCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "artist",
		abstract: "List an artist's releases, newest first."
	)
	
	@Argument(help: "An artist link or ID.")
	var artist: String
	
	@Option(name: [.customLong("type"), .short], help: "Which releases: \(ReleaseType.allCases.map(\.rawValue).joined(separator: ", ")).")
	var type: ReleaseType = .albums
	
	@Option(help: "Maximum number of releases. Defaults to all.")
	var limit: Int?
	
	@OptionGroup var output: OutputOptions
	
	@MainActor
	func run() async throws {
		let session = try loggedInSession()
		let releases = try await artistReleases(session: session, reference: artist, type: type, limit: limit)
		if output.json {
			try printJSON(releases)
		} else {
			releases.releases.forEach { print($0.line(fullDate: true)) }
		}
	}
}

struct NewReleases: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "new-releases",
		abstract: "The newest albums of your favorite artists, as New Releases in the app shows them."
	)
	
	@Flag(name: [.long, .customShort("e")], help: "Include EPs and singles, not only albums.")
	var includeEpsAndSingles = false
	
	@Option(help: "Maximum number of releases.")
	var limit = 40
	
	@OptionGroup var output: OutputOptions
	
	@MainActor
	func run() async throws {
		let session = try loggedInSession()
		let releases = try await newReleases(session: session, includeEpsAndSingles: includeEpsAndSingles, limit: limit)
		if output.json {
			try printJSON(releases)
		} else {
			releases.forEach { print($0.line(fullDate: true)) }
		}
	}
}
