//
//  SortingState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

final class SortingState: ObservableObject {
	// Favorites
	@Published var favoritePlaylistSorting: PlaylistSorting = .dateAdded
	@Published var favoritePlaylistReversed: Bool = false
	
	@Published var favoriteAlbumSorting: AlbumSorting = .dateAdded
	@Published var favoriteAlbumReversed: Bool = false
	
	@Published var favoriteTrackSorting: TrackSorting = .dateAdded
	@Published var favoriteTrackReversed: Bool = false
	
	@Published var favoriteVideoSorting: VideoSorting = .dateAdded
	@Published var favoriteVideoReversed: Bool = false
	
	@Published var favoriteArtistSorting: ArtistSorting = .dateAdded
	@Published var favoriteArtistReversed: Bool = false
	
	// Offline
	@Published var offlinePlaylistSorting: PlaylistSorting = .dateAdded
	@Published var offlinePlaylistReversed: Bool = false
	
	@Published var offlineAlbumSorting: AlbumSorting = .dateAdded
	@Published var offlineAlbumReversed: Bool = false
	
	@Published var offlineTrackSorting: TrackSorting = .dateAdded
	@Published var offlineTrackReversed: Bool = false
}

struct CodableSortingState: Codable {
	// Favorites
	var favoritePlaylistSorting: PlaylistSorting
	var favoritePlaylistReversed: Bool
	
	var favoriteAlbumSorting: AlbumSorting
	var favoriteAlbumReversed: Bool
	
	var favoriteTrackSorting: TrackSorting
	var favoriteTrackReversed: Bool
	
	var favoriteVideoSorting: VideoSorting
	var favoriteVideoReversed: Bool
	
	var favoriteArtistSorting: ArtistSorting
	var favoriteArtistReversed: Bool
	
	// Offline
	var offlinePlaylistSorting: PlaylistSorting
	var offlinePlaylistReversed: Bool
	
	var offlineAlbumSorting: AlbumSorting
	var offlineAlbumReversed: Bool
	
	var offlineTrackSorting: TrackSorting
	var offlineTrackReversed: Bool
}
