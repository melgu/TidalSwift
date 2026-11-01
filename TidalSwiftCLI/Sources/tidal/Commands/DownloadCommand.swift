//
//  DownloadCommand.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation
import TidalSwiftLib

/// Named apart from the library's `Download`
struct DownloadCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "download",
		abstract: "Download a track, album, artist, playlist or video.",
		discussion: """
			Tracks come as FLAC (16 bit, 44.1 kHz), as Tidal only offers the lossy and Hi-Res qualities encrypted. \
			Albums and playlists get a folder of their own, artists one per album. Existing files are replaced.
			"""
	)
	
	@Argument(help: "A link, playlist UUID or ID.")
	var item: String
	
	@Option(name: [.customLong("type"), .short], help: "What the ID is, if not a link.")
	var type: ItemKind?
	
	@Flag(help: "Download Dolby Atmos instead of stereo where available.")
	var atmos = false
	
	@Option(name: [.customLong("out"), .short], help: "Folder to download into. Defaults to the current folder.", completion: .directory)
	var out: String?
	
	@OptionGroup var output: OutputOptions
	
	@MainActor
	func run() async throws {
		let session = try loggedInSession()
		let link = try TidalLink(reference: item, kind: type)
		
		let destination = try downloadFolder(path: out, fallback: .currentDirectory())
		let options = DownloadOptions(audioQuality: .high, preferDolbyAtmos: atmos, destination: destination)
		
		let summary = try await download(session: session, link: link, options: options) { step in
			printToStderr(step)
		}
		
		if output.json {
			try printJSON(summary)
		} else {
			let items = summary.downloadedItems == 1 ? "1 item" : "\(summary.downloadedItems) items"
			print("Downloaded \(items) to \(summary.destination)")
			for failure in summary.failures {
				print("Failed: \(failure.kind.rawValue) \(failure.title): \(failure.reason)")
			}
		}
		if !summary.failures.isEmpty {
			throw ExitCode.failure
		}
	}
}
