//
//  FavoritesSortingState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

final class FavoritesSortingState: ObservableObject {
	@Published var playlistSorting: PlaylistSorting = .dateAdded
	@Published var playlistReversed: Bool = false
	
	@Published var albumSorting: AlbumSorting = .dateAdded
	@Published var albumReversed: Bool = false
	
	@Published var trackSorting: TrackSorting = .dateAdded
	@Published var trackReversed: Bool = false
	
	@Published var videoSorting: VideoSorting = .dateAdded
	@Published var videoReversed: Bool = false
	
	@Published var artistSorting: ArtistSorting = .dateAdded
	@Published var artistReversed: Bool = false
}

struct CodableFavoritesSortingState: Codable {
	var playlistSorting: PlaylistSorting
	var playlistReversed: Bool
	
	var albumSorting: AlbumSorting
	var albumReversed: Bool
	
	var trackSorting: TrackSorting
	var trackReversed: Bool
	
	var videoSorting: VideoSorting
	var videoReversed: Bool
	
	var artistSorting: ArtistSorting
	var artistReversed: Bool
}
