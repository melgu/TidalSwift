//
//  Others.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 19.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation

public enum AudioQuality: String, Codable {
	case max = "HI_RES_LOSSLESS"	// Lossless, 24 Bit, 192 kHz
	case high = "LOSSLESS"			// Lossless, 16 Bit / 44,1 kHz
	case medium = "HIGH"			// 320 kbps
	case low = "LOW"				// 96 kbps
}

extension AudioQuality: CaseIterable {}
extension AudioQuality: Identifiable {
	public var id: Self { self }
}

struct LoginResponse: Decodable {
	let userId: Int
	let sessionId: String
	let countryCode: String
}
