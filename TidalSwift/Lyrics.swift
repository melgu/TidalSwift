//
//  Lyrics.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct LyricsObject: Decodable {
	public let lyric: String
	public let err: String
}

class Lyrics {
	var lastTrack: Track?
	var lastLyrics: String?
	
	func getLyrics(for track: Track) -> String? {
		if track == lastTrack {
			return lastLyrics
		}
		
		guard let artist = track.artists.first else {
			return ""
		}
		guard let artistString = artist.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			  let trackString = track.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			  let url = URL(string: "http://lyric-api.herokuapp.com/api/find/\(artistString)/\(trackString)") else {
			print("Lyrics failed (URL Error)")
			return nil
		}
		let request = URLRequest(url: url)
		
		var downloadedContent: Data?
		
		let semaphore = DispatchSemaphore(value: 0)
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data,
				let response = response as? HTTPURLResponse,
				error == nil else { // check for fundamental networking error
					print("error", error ?? "Unknown error")
					semaphore.signal()
					return
			}
			
			guard (200..<299) ~= response.statusCode else {	// check for http errors
				print("statusCode should be 2xx, but is \(response.statusCode)")
				print("response = \(response)")
				semaphore.signal()
				return
			}
			
			downloadedContent = data
			semaphore.signal()
		}
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		guard let content = downloadedContent else {
			print("Lyrics failed (HTTP Error)")
			return nil
		}
		
		var optionalLyricsResponse: LyricsObject?
		do {
			optionalLyricsResponse = try JSONDecoder().decode(LyricsObject.self, from: content)
		} catch {
			print("Lyrics failed (JSON Parse Error)")
		}
		
		guard let lyricsResponse = optionalLyricsResponse else {
			print("Lyrics failed (JSON Parse returns nil)")
			return nil
		}
		
		if lyricsResponse.err != "none" && lyricsResponse.err != "not found" {
			print("Lyrics Error: \(lyricsResponse.err)")
		}
		
		if lyricsResponse.lyric == "Unfortunately, we are not licensed to display the full lyrics for this song at the moment. Hopefully we will be able to in the future. Until then... how about a random page?" {
			return nil
		}
		if lyricsResponse.lyric == "" {
			return nil
		}
		
		lastTrack = track
		lastLyrics = String(htmlEncodedString: lyricsResponse.lyric.replacingOccurrences(of: "\n", with: "<br>"))
		return lastLyrics
	}
}

extension String {
	init(htmlEncodedString: String) {
		self.init()
		
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
