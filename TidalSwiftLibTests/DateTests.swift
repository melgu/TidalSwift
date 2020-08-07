//
//  DateTests.swift
//  TidalSwiftLibTests
//
//  Created by Melvin Gundlach on 07.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import XCTest
@testable import TidalSwiftLib

class DateTests: XCTestCase {
	func testDateDecoder() {
		// Tests if the DateDecoder defined at the bottom of Codable correctly decodes a date.
		// Makes sure there is no time zone switching.
		let rawString = "2016-07-15"
		let date = DateFormatter.iso8601OptionalTime.date(from: rawString)!
		let resultString = "2016-07-15 00:00:00 +0000"
		XCTAssertEqual(resultString, "\(date)")
		
		// Test sub-second accuracy
		let subSecondString = "2019-03-28T06:49:21.123GMT"
		let subSecondDate = DateFormatter.iso8601OptionalTime.date(from: subSecondString)!
		let wrongResult = "2019-03-28T06:49:21.000GMT"
		let subSecondResult = DateFormatter.iso8601OptionalTime.string(from: subSecondDate)
		XCTAssertNotEqual(wrongResult, subSecondResult)
		XCTAssertEqual(subSecondString, subSecondResult)
	}
	
	func testDateOnlyFormatter() {
		let rawString = "2019-03-28T06:49:21.123GMT"
		let date = DateFormatter.iso8601OptionalTime.date(from: rawString)!
		let formattedDateString = DateFormatter.dateOnly.string(from: date)
		XCTAssertEqual(formattedDateString, "28. March 2019")
	}
}
