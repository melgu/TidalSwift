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
	
	@State var searchText: String = ""
	@State var fixedSearchText: String = ""
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		let selectionBinding = Binding<String?>(
			get: { self.viewState.viewType },
			set: {
				print("View: \($0 ?? "nil")")
				self.viewState.clear()
				if $0 != nil {
					self.viewState.push(view: TidalSwiftView(viewType: ViewType(rawValue: $0!)!))
				} else {
					self.viewState.push(view: TidalSwiftView(viewType: .none))
				}
		})
		return NavigationView {
			MasterView(selection: selectionBinding, searchText: $searchText, fixedSearchText: $fixedSearchText, session: session)
			DetailView(fixedSearchText: fixedSearchText, session: session, player: player)
				.frame(minWidth: 580)
		}
		.frame(minHeight: 500)
	}
}

struct MasterView: View {
	@Binding var selection: String?
	@Binding var searchText: String
	@Binding var fixedSearchText: String
	
	let session: Session
	
	private let news = ["New Releases"]
	private let favorites = ["Playlists", "Albums", "Tracks", "Videos", "Artists"]
//	private let views = ["SingleAlbum", "SinglePlaylist"]
	
	var body: some View {
		VStack {
			TextField("Search", text: $searchText, onCommit: {
				if self.searchText != "" {
					print(self.searchText)
					self.fixedSearchText = self.searchText
					self.selection = "Search"
//					let window = (NSApp.delegate as? AppDelegate)?.window
//					window?.makeFirstResponder(window?.initialFirstResponder)
				}
			})
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding(.top, 10)
				.padding([.leading, .trailing], 5)
			List(selection: $selection) {
				Section(header: Text("News")) {
					ForEach(news, id: \.self) { viewType in
						Text(viewType)
					}
				}
				Section(header: Text("Favorites")) {
					ForEach(favorites, id: \.self) { viewType in
						Text(viewType)
					}
				}
			}.listStyle(SidebarListStyle())
		}
	}
}

struct DetailView: View {
	let fixedSearchText: String
	
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	
	var body: some View {
		VStack {
			PlayerInfoView(session: session, player: player)
			HStack {
				// Search
				if viewState.viewType == "Search" {
					SearchView(searchText: fixedSearchText, session: session, player: player)
				}
				
				// News
				else if viewState.viewType == "New Releases" {
					NewReleases(session: session, player: player)
				}
				
				// Favorites
				else if viewState.viewType == "Playlists" {
					FavoritePlaylists(session: session, player: player)
				} else if viewState.viewType == "Albums" {
					FavoriteAlbums(session: session, player: player)
				} else if viewState.viewType == "Tracks" {
					FavoriteTracks(session: session, player: player)
				} else if viewState.viewType == "Videos" {
					FavoriteVideos(session: session, player: player)
				} else if viewState.viewType == "Artists" {
					FavoriteArtists(session: session, player: player)
				}  else if viewState.viewType == "SingleArtist" {
					ArtistView(artist: viewState.artist, session: session, player: player)
				} else if viewState.viewType == "SingleAlbum" {
					AlbumView(album: viewState.album, session: session, player: player)
				} else if viewState.viewType == "SinglePlaylist" {
					PlaylistView(playlist: viewState.playlist, session: session, player: player)
				}
			}
			if viewState.viewType == "" || viewState.viewType == nil {
				Spacer()
			}
		}
//		.frame(width: 800, height: 700)
	}
}


//struct MasterDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MasterDetailView()
//    }
//}
