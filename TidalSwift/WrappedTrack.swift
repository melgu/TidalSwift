//
//  WrappedTrack.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 02.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

struct WrappedTrack: Codable, Identifiable, Equatable {
	let id: Int
	let track: Track
	
	static func == (lhs: WrappedTrack, rhs: WrappedTrack) -> Bool {
		lhs.track == rhs.track
	}
}

extension Array where Element == Track {
	func wrap() -> [WrappedTrack] {
		var r: [WrappedTrack] = []
		for i in 0..<self.count {
			r.append(WrappedTrack(id: i, track: self[i]))
		}
		return r
	}
}

extension Array where Element == WrappedTrack {
	func unwrapped() -> [Track] {
		self.map { $0.track }
	}
}
