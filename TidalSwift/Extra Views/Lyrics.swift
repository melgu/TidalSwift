//
//  Lyrics.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

private struct LyricsObject: Decodable {
	let lyric: String
	let error: String
	
	enum CodingKeys: String, CodingKey {
		case lyric
		case error = "err"
	}
}

class Lyrics {
	static let shared: Lyrics = .init()
	
	enum Error: Swift.Error {
		case invalidURL
		case missingArtist
		case notLicensed
		case notFound
		case missingLyrics
	}
	
	private var cache: URLCache = .init()
	private lazy var decoder = JSONDecoder()
	
	private init() {}
	
	func lyrics(for track: Track) async throws -> String {
		guard let artist = track.artists.first else {
			throw Error.missingArtist
		}
		guard let artistString = artist.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			  let trackString = track.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			  let url = URL(string: "http://lyric-api.herokuapp.com/api/find/\(artistString)/\(trackString)") else {
			print("Lyrics failed (URL Error)")
			throw Error.invalidURL
		}
		let request = URLRequest(url: url)
		
		let lyricsData: Data
		if let cachedResponse = cache.cachedResponse(for: request) {
			lyricsData = cachedResponse.data
		} else {
			let (data, response) = try await URLSession.shared.data(for: request)
			cache.storeCachedResponse(.init(response: response, data: data), for: request)
			lyricsData = data
		}
		
		let lyricsObject = try decoder.decode(LyricsObject.self, from: lyricsData)
		
		guard lyricsObject.error != "not found" else {
			throw Error.notFound
		}
		
		guard lyricsObject.error != "Unfortunately, we are not licensed to display the full lyrics for this song at the moment. Hopefully we will be able to in the future. Until then... how about a random page?" else {
			throw Error.notLicensed
		}
		
		guard !lyricsObject.lyric.isEmpty else {
			throw Error.missingLyrics
		}
		
		return String(htmlEncodedString: lyricsObject.lyric.replacingOccurrences(of: "\n", with: "<br>"))
	}
}

extension String {
	init(htmlEncodedString: String) {
		guard let data = htmlEncodedString.data(using: .utf8) else {
			self = htmlEncodedString
			return
		}
		
		let decoded = try? NSAttributedString(data: data, options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ], documentAttributes: nil).string

        self = decoded ?? htmlEncodedString
	}
}
