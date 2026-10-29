//
//  DownloadOptions.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 29.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

extension Session {
	/// Downloads use the offline settings and go to the Downloads folder, the only one the sandbox allows writing to
	var downloadOptions: DownloadOptions {
		DownloadOptions(
			audioQuality: config.offlineAudioQuality,
			preferDolbyAtmos: helpers.offline.preferDolbyAtmos,
			destination: .downloadsDirectory
		)
	}
}
