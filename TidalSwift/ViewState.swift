//
//  ViewState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

final class ViewState: ObservableObject {
	@Published var viewType: String?
	@Published var artist: Artist?
	@Published var album: Album?
	@Published var playlist: Playlist?
}
