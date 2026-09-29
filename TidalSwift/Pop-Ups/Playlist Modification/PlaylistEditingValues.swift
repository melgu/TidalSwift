//
//  PlaylistEditingValues.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 25.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

@Observable
final class PlaylistEditingValues {
	var showAddTracksModal: Bool = false
	var tracks: [Track] = []
	
	var showRemoveTracksModal: Bool = false
	var indexToRemove: Int?
	
	var showDeleteModal: Bool = false
	var showEditModal: Bool = false
	var playlist: Playlist?
}
