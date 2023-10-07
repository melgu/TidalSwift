//
//  User.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func subscriptionInfo() async -> Subscription? {
		guard let userId else { return nil }
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)/subscription")!
		do {
			let response: Subscription = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public func user(userId: Int) async -> User? {
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)")!
		do {
			let response: User = try await Network.get(url: url, parameters: sessionParameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response
		} catch {
			return nil
		}
	}
	
	public func userPlaylists(userId: Int, order: AlbumOrder? = nil, orderDirection: OrderDirection? = nil) async -> [Playlist]? {
		let url = URL(string: "\(AuthInformation.APILocation)/users/\(userId)/playlists")!
		var parameters = sessionParameters
		if let order = order {
			parameters["order"] = "\(order.rawValue)"
		}
		if let orderDirection = orderDirection {
			parameters["orderDirection"] = "\(orderDirection.rawValue)"
		}
		
		do {
			let response: Playlists = try await Network.get(url: url, parameters: parameters, accessToken: config.accessToken, xTidalToken: config.apiToken)
			return response.items
		} catch {
			return nil
		}
	}
}
