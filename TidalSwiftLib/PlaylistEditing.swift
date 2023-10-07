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
		self.baseUrl = "\(AuthInformation.APILocation)/playlists"
	}
	
	func etag(for playlistId: String) async -> Int {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		do {
			let response = try await Network.get(url: url, parameters: session.sessionParameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response.etag ?? -1
		} catch {
			return -1
		}
	}
	
	public func addTracks(_ trackIds: [Int], to playlistId: String, duplicate: Bool) async -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items")!
		var parameters = session.sessionParameters
		var trackIdsString = ""
		for id in trackIds {
			trackIdsString += "\(id),"
		}
		trackIdsString = String(trackIdsString.dropLast())
		parameters["trackIds"] = trackIdsString
		parameters["onDupes"] = duplicate ? "ADD" : "FAIL"
		do {
			_ = try await Network.post(url: url, parameters: parameters, etag: etag(for: playlistId), accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return true
		} catch {
			return false
		}
	}
	
	public func addTrack(_ trackId: Int, to playlistId: String, duplicate: Bool) async -> Bool {
		await addTracks([trackId], to: playlistId, duplicate: duplicate)
	}
	
	public func removeItem(atIndex index: Int, from playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items/\(index)")!
		var parameters = session.sessionParameters
		parameters["order"] = "INDEX"
		parameters["orderDirection"] = "ASC"
		do {
			_ = try await Network.delete(url: url, parameters: parameters, etag: etag(for: playlistId), accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return true
		} catch {
			return false
		}
	}
	
	public func moveItem(fromIndex: Int, toIndex: Int, in playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)/items/\(fromIndex)")!
		var parameters = session.sessionParameters
		parameters["toIndex"] = "\(toIndex)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, etag: etag(for: playlistId), accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return true
		} catch {
			return false
		}
	}
	
	public func create(title: String, description: String) async -> Playlist? {
		guard let userId = session.userId else {
			return nil
		}
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)/playlists")!
		var parameters = session.sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		do {
			let response: Playlist = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public func edit(playlistId: String, title: String, description: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		var parameters = session.sessionParameters
		parameters["title"] = "\(title)"
		parameters["description"] = "\(description)"
		do {
			_ = try await Network.post(url: url, parameters: parameters, accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return true
		} catch {
			return false
		}
	}
	
	public func delete(playlistId: String) async -> Bool {
		let url = URL(string: "\(baseUrl)/\(playlistId)")!
		do {
			_ = try await Network.delete(url: url, parameters: session.sessionParameters, etag: etag(for: playlistId), accessToken: session.config.accessToken, xTidalToken: session.config.apiToken)
			return true
		} catch {
			return false
		}
	}
}
