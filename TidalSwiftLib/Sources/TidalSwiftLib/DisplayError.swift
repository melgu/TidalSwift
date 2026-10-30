//
//  DisplayError.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import OSLog

private let logger = Logger(category: "DisplayError")

func displayError(title: String, content: String) {
	// Comment out while unit testing to prevent pop-ups
	
	logger.error("\(title). \(content)")
}
