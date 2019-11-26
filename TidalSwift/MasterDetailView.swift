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
			get: { self.viewState.stack.last?.viewType },
			set: {
//				print("Selection View: \($0?.rawValue ?? "nil")")
				self.viewState.clear()
				if $0 != nil {
					self.viewState.push(view: TidalSwiftView(viewType: $0!))
				}
		})
		return NavigationView {
			MasterView(selection: selectionBinding, searchTerm: searchTerm, session: session)
			DetailView(session: session, player: player)
				.frame(minWidth: 580)
		}
		.frame(minHeight: 500)
	}
}

struct MasterView: View {
	@Binding var selection: ViewType?
	@Binding var searchTerm: String
	
	let session: Session
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			SearchField(searchTerm: $searchTerm, selection: $selection)
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
					Text("Artists").tag(ViewType.favoriteArtists)
				}
			}.listStyle(SidebarListStyle())
		}
	}
}

struct SearchField: View {
	@Binding var searchTerm: String
	@Binding var selection: ViewType?
	
	var body: some View {
		TextField("Search", text: $searchTerm, onEditingChanged: {_ in
			print("Search Change: \(self.searchTerm)")
			self.selection = .search
//			unowned let window = (NSApp.delegate as? AppDelegate)?.window
//			window?.makeFirstResponder(window?.initialFirstResponder)
		})
			.textFieldStyle(RoundedBorderTextFieldStyle())
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
			if viewState.stack.isEmpty {
				Spacer()
			} else {
				HStack {
					// Search
					if viewState.stack.last!.viewType == .search {
						SearchView(session: session, player: player)
					}
						
					// News
					else if viewState.stack.last!.viewType == .newReleases {
						NewReleases(session: session, player: player)
					} else if viewState.stack.last!.viewType == .myMixes {
						MyMixes(session: session, player: player)
					}
						
					// Favorites
					else if viewState.stack.last!.viewType == .favoritePlaylists {
						FavoritePlaylists(session: session, player: player)
					} else if viewState.stack.last!.viewType == .favoriteAlbums {
						FavoriteAlbums(session: session, player: player)
					} else if viewState.stack.last!.viewType == .favoriteTracks {
						FavoriteTracks(session: session, player: player)
					} else if viewState.stack.last!.viewType == .favoriteVideos {
						FavoriteVideos(session: session, player: player)
					} else if viewState.stack.last!.viewType == .favoriteArtists {
						FavoriteArtists(session: session, player: player)
						
					// Single Things
					}  else if viewState.stack.last!.viewType == .artist {
						ArtistView(session: session, player: player, artist: viewState.stack.last!.artist)
					} else if viewState.stack.last!.viewType == .album {
						AlbumView(session: session, player: player, album: viewState.stack.last!.album)
					} else if viewState.stack.last!.viewType == .playlist {
						PlaylistView(session: session, player: player, playlist: viewState.stack.last!.playlist)
					} else if viewState.stack.last!.viewType == .mix {
						MixPlaylistView(session: session, player: player, mix: viewState.stack.last!.mix)
					}
				}
			}
		}
	}
}
