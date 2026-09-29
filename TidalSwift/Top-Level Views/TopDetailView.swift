//
//  MasterDetailView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 20.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct TopDetailView: View {
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
	}
	
	var body: some View {
		let selectionBinding = Binding<ViewType?>(
			get: { viewState.stack.last?.viewType },
			set: { newValue in
				Task {
	//				print("Selection View: \(newValue?.rawValue ?? "nil")")
					viewState.clearStack()
					if let viewType = newValue {
						viewState.push(view: TidalSwiftView(viewType: viewType))
					}
				}
			})
		return NavigationView {
			TopView(selection: selectionBinding, session: session)
			DetailView(session: session, player: player)
				.frame(minWidth: 850)
		}
		.frame(minHeight: 500)
	}
}

private struct TopView: View {
	@Binding var selection: ViewType?
//	@Binding var searchTerm: String
	
	let session: Session
	
	@Environment(ViewState.self) private var viewState
	
	@State private var becomeFirstResponder = true
	
	var body: some View {
		VStack {
			SearchField(selection: $selection, searchTerm: viewState.searchTerm)
				.padding(.top, 10)
				.padding(.horizontal, 5)
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

private struct SearchField: View {
	@Binding var selection: ViewType?
	
	@Environment(ViewState.self) private var viewState
	
	@State var searchTerm: String
	@FocusState private var isFocused: Bool
	
	var body: some View {
		TextField("Search", text: $searchTerm, onCommit: {
			print("Search Commit: \(searchTerm)")
			viewState.searchTerm = searchTerm
			if !searchTerm.isEmpty /*&& searchTerm != viewState.lastSearchTerm*/ {
				selection = .search
			}
		})
		.textFieldStyle(RoundedBorderTextFieldStyle())
		.focused($isFocused)
		.onAppear {
			// AppKit makes the first text field the window's first responder when it opens.
			// Give that up, so Space can control playback right away.
			Task {
				isFocused = false
			}
		}
		.onExitCommand {
			isFocused = false
		}
		.focusedSceneValue(\.searchFieldFocus, $isFocused)
	}
}

extension FocusedValues {
	@Entry var searchFieldFocus: FocusState<Bool>.Binding?
}

private struct DetailView: View {
	let session: Session
	let player: Player
	
	@Environment(ViewState.self) private var viewState
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
		print("init DetailView")
	}
	
	private var placeHolderView: some View {
		HStack {
			VStack {
				Spacer(minLength: 0)
			}
			Spacer(minLength: 0)
		}
	}
	
	var body: some View {
		VStack(spacing: 0) {
			PlayerInfoView(session: session, player: player)
				.padding(.bottom)
			Divider()
			if let viewType = viewState.stack.last?.viewType {
				Group {
					// Search
					if viewType == .search {
						SearchView(session: session, player: player)
					}
					
					// News
					else if viewType == .newReleases {
						NewReleases(session: session, player: player)
					} else if viewType == .myMixes {
						MyMixes(session: session, player: player)
					}
					
					// Favorites
					else if viewType == .favoritePlaylists {
						FavoritePlaylists(session: session, player: player)
					} else if viewType == .favoriteAlbums {
						FavoriteAlbums(session: session, player: player)
					} else if viewType == .favoriteTracks {
						FavoriteTracks(session: session, player: player)
					} else if viewType == .favoriteVideos {
						FavoriteVideos(session: session, player: player)
					} else if viewType == .favoriteArtists {
						FavoriteArtists(session: session, player: player)
					}
					
					else if viewType == .offlinePlaylists {
						OfflinePlaylistsView(session: session, player: player)
					} else if viewType == .offlineAlbums {
						OfflineAlbumsView(session: session, player: player)
					} else if viewType == .offlineTracks {
						OfflineTracksView(session: session, player: player)
					}
					
					// Single Things
					else if viewType == .artist {
						ArtistView(session: session, player: player, viewState: viewState)
					} else if viewType == .album {
						AlbumView(session: session, player: player)
					} else if viewType == .playlist {
						PlaylistView(session: session, player: player)
					} else if viewType == .mix {
						MixPlaylistView(session: session, player: player)
					}
				}
			} else {
				Spacer()
			}
		}
	}
}
