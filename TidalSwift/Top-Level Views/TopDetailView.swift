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
	
	@EnvironmentObject var viewState: ViewState
	
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
                .focusable()
                .focusEffectDisabled()
                .onKeyPress(.space) {
                    player.togglePlay()
                    return .ignored
                }
		}
		.frame(minHeight: 500)
	}
}

struct TopView: View {
	@Binding var selection: ViewType?
//	@Binding var searchTerm: String
	
	let session: Session
	
	@EnvironmentObject var viewState: ViewState
	
	@State var becomeFirstResponder = true
	
	var body: some View {
		VStack {
			SearchField(selection: $selection, searchTerm: viewState.searchTerm)
				.padding(.top, 10)
				.padding(.horizontal, 10)
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
        
		HStack(spacing: 8) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)
			TextField("Search", text: $searchTerm, onCommit: {
				print("Search Commit: \(searchTerm)")
				viewState.searchTerm = searchTerm
				if !searchTerm.isEmpty /*&& searchTerm != viewState.lastSearchTerm*/ {
					selection = .search
				}
			})
			.textFieldStyle(.plain)
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 8)
		.background(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.fill(
					{
						#if os(macOS)
						return Color(nsColor: .textBackgroundColor)
						#else
						return Color(uiColor: .secondarySystemBackground)
						#endif
					}()
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.stroke(Color.secondary.opacity(0.2), lineWidth: 1)
		)
		.font(.system(size: 14))
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
		VStack(spacing: 0) {
            PlayerInfoView(session: session, player: player)
                .frame(height:80)
                
				
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

