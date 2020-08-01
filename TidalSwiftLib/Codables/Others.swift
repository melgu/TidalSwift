//
//  Others.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum AudioQuality: String, Codable {
	case master = "HI_RES"
	case hifi = "LOSSLESS"
	case high = "HIGH"
	case low = "LOW"
}

struct LoginResponse: Decodable {
	let userId: Int
	let sessionId: String
	let countryCode: String
}
