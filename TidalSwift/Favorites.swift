//
//  Favorites.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct FavoritePlaylists: View {
	let session: Session
	
    var body: some View {
        Text("Playlists")
			.font(.largeTitle)
    }
}

struct FavoriteAlbums: View {
	let session: Session
	
    var body: some View {
		AlbumGrid(session: session, albums: favoriteAlbums2Albums(favoriteAlbums: session.favorites!.albums()!))
    }
}

func favoriteAlbums2Albums(favoriteAlbums: [FavoriteAlbum]) -> [Album] {
	favoriteAlbums.map { $0.item }
}

struct FavoriteTracks: View {
	let session: Session
	
    var body: some View {
		VStack(alignment: .leading) {
			Text("Favorite Tracks")
				.font(.largeTitle)
			
			ScrollView {
				HStack {
					VStack(alignment: .leading) {
						ForEach(favoriteTracks2Tracks(favoriteTracks: session.favorites!.tracks()!)) { track in
							TrackRowFront(session: self.session, track: track, showCover: true)
						}
					}
					VStack(alignment: .trailing) {
						ForEach(favoriteTracks2Tracks(favoriteTracks: session.favorites!.tracks()!)) { track in
							TrackRowBack(track: track)
						}
					}
				}
			}
		}
    }
}

func favoriteTracks2Tracks(favoriteTracks: [FavoriteTrack]) -> [Track] {
	favoriteTracks.map { $0.item }
}

struct FavoriteVideos: View {
	let session: Session
	
    var body: some View {
        Text("Videos")
			.font(.largeTitle)
    }
}

struct FavoriteArtists: View {
	let session: Session
	
    var body: some View {
        Text("Artists")
			.font(.largeTitle)
		
	}
}

//struct Favorites_Previews: PreviewProvider {
//    static var previews: some View {
//        Favorites()
//    }
//}
