//
//  Array+Element.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 07.10.23.
//  Copyright © 2023 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Array {
	func element(at index: Int) -> Element? {
		guard index < count else { return nil }
		return self[index]
	}
}
