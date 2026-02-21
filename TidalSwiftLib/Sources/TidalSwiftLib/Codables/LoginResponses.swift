//
//  LoginResponses.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 20.04.21.
//  Copyright © 2021 Melvin Gundlach. All rights reserved.
//

import Foundation

struct DeviceAuthorizationResponse: Decodable {
	let deviceCode: UUID
	let userCode: String
	let verificationUri: URL
	let verificationUriComplete: URL
	let expiresIn: Int
	let interval: Int
}

struct TokenSuccessResponse: Decodable {
	let accessToken: String
	var refreshToken: String? = nil // Is not included in Refresh Token response
	let tokenType: String // "Bearer"
	let expiresIn: Int
	let user: LoginUser
	
	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
		case tokenType = "token_type"
		case expiresIn = "expires_in"
		case user
	}
}

struct TokenErrorResponse: Decodable {
	let status: Int
	let error: String?
	let subStatus: Int
	let errorDescription: String
	
	enum CodingKeys: String, CodingKey {
		case status
		case error
		case subStatus = "sub_status"
		case errorDescription = "error_description"
	}
}
