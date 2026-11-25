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
	/// The tracks and videos to add, or the one to remove
	var items: [PlaylistItem] = []
	
	/// Sets the tracks to add, or the one to remove
	func set(tracks: [Track]) {
		items = tracks.map(PlaylistItem.track)
	}
	
	var showRemoveTracksModal: Bool = false
	var indexToRemove: Int?
	
	var showDeleteModal: Bool = false
	var showEditModal: Bool = false
	var playlist: Playlist?
}
