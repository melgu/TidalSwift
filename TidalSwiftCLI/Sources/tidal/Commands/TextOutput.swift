//
//  TextOutput.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 31.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import ArgumentParser
import Foundation

// One line per item, starting with the ID other commands take

extension ItemKind: ExpressibleByArgument {}
extension ReleaseType: ExpressibleByArgument {}

func formatDuration(_ seconds: Int) -> String {
	let hours = seconds / 3600
	let minutes = seconds / 60 % 60
	let rest = String(format: "%02d", seconds % 60)
	return hours > 0 ? "\(hours):\(String(format: "%02d", minutes)):\(rest)" : "\(minutes):\(rest)"
}

extension TrackSummary {
	var line: String {
		"\(id)  \(title) – \(artists) (\(album), \(formatDuration(duration)))"
	}
}

extension AlbumSummary {
	var line: String {
		line(fullDate: false)
	}
	
	/// The full date matters for lists of releases, the year is enough elsewhere
	func line(fullDate: Bool) -> String {
		var details: [String] = []
		if let releaseDate {
			details.append(fullDate
				? releaseDate.formatted(date: .abbreviated, time: .omitted)
				: String(Calendar.current.component(.year, from: releaseDate)))
		}
		if let numberOfTracks {
			details.append(numberOfTracks == 1 ? "1 track" : "\(numberOfTracks) tracks")
		}
		// Tells apart the separate albums Tidal lists for these versions
		if dolbyAtmos {
			details.append("Dolby Atmos")
		}
		if hiRes {
			details.append("Hi-Res")
		}
		if explicit == true {
			details.append("explicit")
		}
		let artistString = artists.map { " – \($0)" } ?? ""
		let detailString = details.isEmpty ? "" : " (\(details.joined(separator: ", ")))"
		return "\(id)  \(title)\(artistString)\(detailString)"
	}
}

extension ArtistSummary {
	var line: String {
		"\(id)  \(name)"
	}
}

extension PlaylistSummary {
	var line: String {
		var details = [numberOfTracks == 1 ? "1 track" : "\(numberOfTracks) tracks"]
		if isOwn {
			details.append("yours")
		} else if let creator, !creator.isEmpty {
			details.append("by \(creator)")
		}
		return "\(uuid)  \(title) (\(details.joined(separator: ", ")))"
	}
}

extension VideoSummary {
	var line: String {
		"\(id)  \(title) – \(artists) (\(formatDuration(duration)))"
	}
}

extension SearchResults {
	/// With a heading per kind if there's more than one
	func printLines() {
		let sections = [
			("Tracks", tracks.map(\.line)),
			("Albums", albums.map(\.line)),
			("Artists", artists.map(\.line)),
			("Playlists", playlists.map(\.line)),
			("Videos", videos.map(\.line))
		].filter { !$0.1.isEmpty }
		
		if sections.isEmpty {
			printToStderr("Nothing found")
		}
		for (index, (heading, lines)) in sections.enumerated() {
			if sections.count > 1 {
				if index > 0 {
					print()
				}
				print(heading)
			}
			lines.forEach { print($0) }
		}
	}
}
