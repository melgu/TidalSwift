//
//  ImageLoader.swift
//  SwiftUI Player
//
//  Created by Melvin Gundlach on 02.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

class ImageLoader {
	
	class func load(url: String, placeholder: Image = Image("Single Black Pixel")) -> Image {
		
		var downloadedImage = placeholder
		
		guard let imageURL = URL(string: url) else {
			return downloadedImage
		}
		
		let semaphore = DispatchSemaphore(value: 0)
		URLSession.shared.dataTask(with: imageURL) { data, response, error in
			
			guard let data = data, error == nil, let nsImage = NSImage(data: data) else {
				semaphore.signal()
				return
			}
			
			downloadedImage = Image(nsImage: nsImage)
			semaphore.signal()
		}.resume()
		
		semaphore.wait()
		return downloadedImage
	}
	
	
}
