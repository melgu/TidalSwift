//
//  Pasteboard.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 03.12.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI
import TidalSwiftLib

class Pasteboard {
	static func copy(string: String) {
		#if canImport(AppKit)
		let pb = NSPasteboard.init(name: NSPasteboard.Name.general)
		pb.declareTypes([.string], owner: nil)
		pb.setString(string, forType: .string)
		#else
		UIPasteboard.general.string = string
		#endif
	}
	
	static func tidalLink() -> TidalLink? {
		#if canImport(AppKit)
		let string = NSPasteboard.general.string(forType: .string)
		#else
		let string = UIPasteboard.general.string
		#endif
		return string.flatMap { TidalLink(string: $0) }
	}
}
