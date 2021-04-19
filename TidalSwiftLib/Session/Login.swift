//
//  Login.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func populateVariablesForAuthorization() -> Bool {
		let url = URL(string: "\(config.apiLocation)/sessions")!
		let response = Network.get(url: url, parameters: sessionParameters, authorization: config.authorization, xTidalToken: config.apiToken)
		
		guard let content = response.content else {
			displayError(title: "Sessions Info failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return false
		}
		
		var sessions: Sessions?
		do {
			sessions = try customJSONDecoder().decode(Sessions.self, from: content)
		} catch {
			displayError(title: "Sessions Info failed (JSON Parse Error)", content: "\(error)")
			return false
		}
		
		if let sessions = sessions {
			self.countryCode = sessions.countryCode
			self.userId = sessions.userId
			self.favorites = Favorites(session: self, userId: sessions.userId)
			return true
		}
			
		return false
	}
}

