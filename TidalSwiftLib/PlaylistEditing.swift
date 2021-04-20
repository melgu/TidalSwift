//
//  PlaylistEditing.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

public class PlaylistEditing {
	unowned let session: Session
	let baseUrl: String
	
	init(session: Session) {
		self.session = session
		self.baseUrl = "\(session.config.apiLocation)/playlists"
	}
	
	func etag(for playlistId: String) -> Int {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		let response = Network.get(url: url, parameters: session.sessionParameters, authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.etag ?? -1
	}
	
	public func addTracks(_ trackIds: [Int], to playlistId: String, duplicate: Bool) -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items")!
		var parameters = session.sessionParameters
		var trackIdsString = ""
		for id in trackIds {
			trackIdsString += "\(id),"
		}
		trackIdsString = String(trackIdsString.dropLast())
		parameters["trackIds"] = trackIdsString
		parameters["onDupes"] = duplicate ? "ADD" : "FAIL"
		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId), authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.ok
	}
	
	public func addTrack(_ trackId: Int, to playlistId: String, duplicate: Bool) -> Bool {
		addTracks([trackId], to: playlistId, duplicate: duplicate)
	}
	
	public func removeItem(atIndex index: Int, from playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items/\(index)")!
		var parameters = session.sessionParameters
		parameters["order"] = "INDEX"
		parameters["orderDirection"] = "ASC"
		let response = Network.delete(url: url, parameters: parameters, etag: etag(for: playlistId), authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.ok
	}
	
	public func moveItem(fromIndex: Int, toIndex: Int, in playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items/\(fromIndex)")!
		var parameters = session.sessionParameters
		parameters["toIndex"] = "\(toIndex)"
		let response = Network.post(url: url, parameters: parameters, etag: etag(for: playlistId), authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.ok
	}
	
	public func create(title: String, description: String) -> Playlist? {
		guard let userId = session.userId else {
			return nil
		}
		let url = URL(string: "\(session.config.apiLocation)/users/\(userId)/playlists")!
		var parameters = session.sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		let response = Network.post(url: url, parameters: parameters, authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Playlist Creation failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var playlistResponse: Playlist?
		do {
			playlistResponse = try customJSONDecoder.decode(Playlist.self, from: content)
		} catch {
			displayError(title: "Playlist Creation failed (JSON Parse Error)", content: "\(error)")
		}
		
		return playlistResponse
	}
	
	public func edit(playlistId: String, title: String, description: String) -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		var parameters = session.sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		let response = Network.post(url: url, parameters: parameters, authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.ok
	}
	
	public func delete(playlistId: String) -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		let response = Network.delete(url: url, parameters: session.sessionParameters, etag: etag(for: playlistId), authorization: session.config.authorization, xTidalToken: session.config.apiToken)
		return response.ok
	}
}
