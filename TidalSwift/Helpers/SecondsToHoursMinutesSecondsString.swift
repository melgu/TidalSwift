//
//  SecondsToHoursMinutesSecondsString.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

func secondsToHoursMinutesSecondsString(seconds: Int) -> String {
	let formatter = DateComponentsFormatter()
	formatter.allowedUnits = [.hour, .minute, .second]
	formatter.unitsStyle = .positional
	
	var s = formatter.string(from: TimeInterval(seconds))!
	if s.count == 1 {
		s = "0:0\(s)"
	} else if s.count == 2 {
		s = "0:\(s)"
	}
	return s
}
