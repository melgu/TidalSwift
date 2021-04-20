//
//  User.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func getSubscriptionInfo() -> Subscription? {
		guard let userId = userId else {
			return nil
		}
		
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/subscription")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Subscription Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var searchResultResponse: Subscription?
		do {
			searchResultResponse = try customJSONDecoder.decode(Subscription.self, from: content)
		} catch {
			displayError(title: "Subscription Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return searchResultResponse
	}
	
	public func getUser(userId: Int) -> User? {
		let url = URL(string: "\(config.apiLocation)/users/\(userId)")!
		let response = Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "User Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var user: User?
		do {
			user = try customJSONDecoder.decode(User.self, from: content)
		} catch {
			displayError(title: "User Info failed (JSON Parse Error)", content: "\(error)")
		}
		
		return user
	}
	
	public func getUserPlaylists(userId: Int, order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/users/\(userId)/playlists")!
		var parameters = sessionParameters
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		let response = Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "User Playlists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var userPlaylistResponse: Playlists?
		do {
			userPlaylistResponse = try customJSONDecoder.decode(Playlists.self, from: content)
		} catch {
			displayError(title: "User Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return userPlaylistResponse?.items
	}
}
