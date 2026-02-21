//
//  Extensions.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

// MARK: Sorting
/// Secondary sorting is always by title

extension Array {
	// Only reversed if b is true
	public func reversed(_ b: Bool) -> [Element] {
		b ? self.reversed() : self
	}
}
