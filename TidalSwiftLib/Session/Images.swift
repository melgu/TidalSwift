//
//  Images.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

extension Session {
	public func getImageUrl(imageId: String, resolution: Int, resolutionY: Int? = nil) -> URL? {
		// Known Sizes (allowed resolutions)
		// Albums: 80, 160, 320, 640, 1280
		// Artists: 160, 320, 480, 750
		// Videos: 80, 160, 320, 640, 750, 1280
		// Playlists: 160, 320, 480, 640, 750
		// Playlists (non-square): 480x320
		// Users: 100, 210
		// FeaturedItem: 1100x800, 550x400 (not square)
		// Mixes: ???
		// Genres: ???
		
		var tempResolutionY: Int
		if let resolutionY = resolutionY {
			tempResolutionY = resolutionY
		} else {
			tempResolutionY = resolution
		}
		
		let path = imageId.replacingOccurrences(of: "-", with: "/")
        let urlString = "\(AuthInformation.ImageLocation)/\(path)/\(resolution)x\(tempResolutionY).jpg"
		return URL(string: urlString)
	}
	
	public func getImage(imageId: String, resolution: Int, resolutionY: Int? = nil) -> NSImage? {
		let urlOrNil = getImageUrl(imageId: imageId, resolution: resolution, resolutionY: resolutionY)
		guard let url = urlOrNil else {
			return nil
		}
		return NSImage(byReferencing: url)
	}
}
