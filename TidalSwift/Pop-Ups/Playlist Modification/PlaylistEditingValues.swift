//
//  PlaylistEditingValues.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 25.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

final class PlaylistEditingValues: ObservableObject {
	@Published var showAddTracksModal: Bool = false
	@Published var tracks: [Track] = []
	
	@Published var showRemoveTracksModal: Bool = false
	@Published var indexToRemove: Int?
	
	@Published var showDeleteModal: Bool = false
	@Published var showEditModal: Bool = false
	@Published var playlist: Playlist?
}
