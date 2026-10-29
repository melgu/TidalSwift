//
//  Logger.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 29.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
	init(category: String) {
		self.init(subsystem: "de.melgu.TidalSwiftLib", category: category)
	}
}
