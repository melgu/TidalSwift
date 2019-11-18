//
//  MasterDetailView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 20.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct MasterDetailView: View {
    let session: Session
	let player: Player
	
//	@State var fixedSearchText: String = ""
	
	@EnvironmentObject var viewState: ViewState
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
	}
	
	var body: some View {
		let searchTerm = Binding<String>(
			get: { self.viewState.searchTerm },
			set: { self.viewState.searchTerm = $0 }
		)
		let selectionBinding = Binding<ViewType?>(
			get: { self.viewState.viewType },
			set: {
				print("View: \($0?.rawValue ?? "nil")")
				self.viewState.clear()
				if $0 != nil {
					self.viewState.push(view: TidalSwiftView(viewType: $0!))
				} else {
					self.viewState.push(view: TidalSwiftView(viewType: nil, searchTerm: self.viewState.fixedSearchTerm))
				}
		})
		return NavigationView {
			MasterView(selection: selectionBinding, searchText: searchTerm, session: session)
			DetailView(session: session, player: player)
				.frame(minWidth: 580)
		}
		.frame(minHeight: 500)
	}
}

struct MasterView: View {
	@Binding var selection: ViewType?
	@Binding var searchText: String
	
	let session: Session
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			TextField("Search", text: $searchText, onCommit: {
				print("Search Commit")
				if self.searchText != "" {
					print("Search Commit: \(self.searchText)")
					self.viewState.fixedSearchTerm = self.searchText
					self.selection = .search
//					let window = (NSApp.delegate as? AppDelegate)?.window
//					window?.makeFirstResponder(window?.initialFirstResponder)
				}
			})
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding(.top, 10)
				.padding([.leading, .trailing], 5)
			List(selection: $selection) {
				Section(header: Text("News")) {
					Text("New Releases").tag(ViewType.newReleases)
					Text("My Mixes").tag(ViewType.myMixes)
				}
				Section(header: Text("Favorites")) {
					Text("Playlists").tag(ViewType.favoritePlaylists)
					Text("Albums").tag(ViewType.favoriteAlbums)
					Text("Tracks").tag(ViewType.favoriteTracks)
					Text("Videos").tag(ViewType.favoriteVideos)
				}
			}.listStyle(SidebarListStyle())
		}
	}
}

struct DetailView: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		print("init DetailView")
	}
	
	var body: some View {
		VStack {
			PlayerInfoView(session: session, player: player)
			HStack {
				// Search
				if viewState.viewType == .search {
					SearchView(searchText: self.viewState.fixedSearchTerm, session: session, player: player)
				}
				
				// News
				else if viewState.viewType == .newReleases {
					NewReleases(session: session, player: player)
				} else if viewState.viewType == .myMixes {
					MyMixes(session: session, player: player)
				}
				
				// Favorites
				else if viewState.viewType == .favoritePlaylists {
					FavoritePlaylists(session: session, player: player)
				} else if viewState.viewType == .favoriteAlbums {
					FavoriteAlbums(session: session, player: player)
				} else if viewState.viewType == .favoriteTracks {
					FavoriteTracks(session: session, player: player)
				} else if viewState.viewType == .favoriteVideos {
					FavoriteVideos(session: session, player: player)
				} else if viewState.viewType == .favoriteArtists {
					FavoriteArtists(session: session, player: player)
				}  else if viewState.viewType == .artist {
					ArtistView(artist: viewState.artist, session: session, player: player)
				} else if viewState.viewType == .album {
					AlbumView(album: viewState.album, session: session, player: player)
				} else if viewState.viewType == .playlist {
					PlaylistView(playlist: viewState.playlist, session: session, player: player)
				} else if viewState.viewType == .mix {
					MixPlaylistView(mix: viewState.mix, session: session, player: player)
				}
			}
			if viewState.viewType == nil {
				Spacer()
			}
		}
	}
}


//struct MasterDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MasterDetailView()
//    }
//}
