//
//  ContentView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib
import ImageIOSwiftUI
import Grid

struct ContentView: View {
	let session: Session
	
	@State var selection: String? = nil
	@State var searchText: String = ""
	
	var body: some View {
		NavigationView {
			MyMasterView(session: session, selection: $selection, searchText: $searchText)
			MyDetailView(session: session, viewType: selection ?? "")
		}
		.frame(width: 1100, height: 700)
	}
}

struct MyMasterView: View {
	let session: Session
	
	@Binding var selection: String?
	@Binding var searchText: String
	
	private let favorites = ["Playlists", "Albums", "Tracks", "Videos", "Artists"]
	
	var body: some View {
		VStack {
			TextField("Search", text: $searchText)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding(.top, 10)
				.padding([.leading, .trailing], 5)
			List(selection: $selection) {
				Section(header: Text("Favorites")) {
					ForEach(favorites, id: \.self) { viewType in
						Text(viewType)
					}
				}
			}.listStyle(SidebarListStyle())
		}
	}
}

struct MyDetailView: View {
	let session: Session
	var viewType: String
	
	var body: some View {
		HStack {
			if viewType == "Playlists" {
				Text("Playlists")
					.font(.largeTitle)
			}
			if viewType == "Albums" {
				AlbumGrid(session: session)
			}
			if viewType == "Tracks" {
				Text("Tracks")
					.font(.largeTitle)
			}
		}
		.frame(width: 800, height: 700)
	}
}



#if DEBUG
//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
#endif
