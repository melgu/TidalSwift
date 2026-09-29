//
//  SortingState.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 22.03.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import TidalSwiftLib

@Observable
final class SortingState {
	// Favorites
	var favoritePlaylistSorting: PlaylistSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var favoritePlaylistReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var favoriteAlbumSorting: AlbumSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var favoriteAlbumReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var favoriteTrackSorting: TrackSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var favoriteTrackReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var favoriteVideoSorting: VideoSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var favoriteVideoReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var favoriteArtistSorting: ArtistSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var favoriteArtistReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	// Offline
	var offlinePlaylistSorting: PlaylistSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var offlinePlaylistReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var offlineAlbumSorting: AlbumSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var offlineAlbumReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	var offlineTrackSorting: TrackSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
	var offlineTrackReversed: Bool = false { didSet { hasUnsavedChanges = true } }
	
	@ObservationIgnored var hasUnsavedChanges = false
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
