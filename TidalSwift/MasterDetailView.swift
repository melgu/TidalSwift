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
		let selectionBinding = Binding<ViewType?>(
			get: { self.viewState.stack.last?.viewType },
			set: {
//				print("Selection View: \($0?.rawValue ?? "nil")")
				self.viewState.clearStack()
				if $0 != nil {
					self.viewState.push(view: TidalSwiftView(viewType: $0!))
				}
		})
		return NavigationView {
			MasterView(selection: selectionBinding, session: session)
			DetailView(session: session, player: player)
				.frame(minWidth: 620)
		}
		.frame(minHeight: 500)
	}
}

struct MasterView: View {
	@Binding var selection: ViewType?
//	@Binding var searchTerm: String
	
	let session: Session
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			SearchField(selection: $selection, searchTerm: viewState.searchTerm)
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
				Section(header: Text("Offline")) {
					Text("Playlists").tag(ViewType.offlinePlaylists)
					Text("Albums").tag(ViewType.offlineAlbums)
					Text("Tracks").tag(ViewType.offlineTracks)
//					Text("Videos").tag(ViewType.favoriteVideos) // Add when Video downloading works
				}
			}.listStyle(SidebarListStyle())
		}
	}
}

struct SearchField: View {
	@Binding var selection: ViewType?
	
	@EnvironmentObject var viewState: ViewState
	
	@State var searchTerm: String
	
	var body: some View {
		TextField("Search", text: $searchTerm, onCommit: {
			print("Search Commit: \(self.searchTerm)")
			self.viewState.searchTerm = self.searchTerm
			if !self.searchTerm.isEmpty {
				self.selection = .search
			}
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
	
	var placeHolderView: some View {
		HStack {
			VStack {
				Spacer(minLength: 0)
			}
			Spacer(minLength: 0)
		}
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
					}
					
					else if viewState.stack.last!.viewType == .offlinePlaylists {
						OfflinePlaylistsView(session: session, player: player)
					} else if viewState.stack.last!.viewType == .offlineAlbums {
						OfflineAlbumsView(session: session, player: player)
					} else if viewState.stack.last!.viewType == .offlineTracks {
						OfflineTracksView(session: session, player: player)
					}
						
						
					// Single Things
					else if viewState.stack.last!.viewType == .artist {
						ArtistView(session: session, player: player, viewState: viewState)
					} else if viewState.stack.last!.viewType == .album {
						AlbumView(session: session, player: player)
					} else if viewState.stack.last!.viewType == .playlist {
						PlaylistView(session: session, player: player)
					} else if viewState.stack.last!.viewType == .mix {
						MixPlaylistView(session: session, player: player)
					}
				}
			}
		}
	}
}
