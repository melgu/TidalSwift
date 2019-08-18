//
//  ContentView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

struct ContentView: View {
	var session: Session
	var album: Album
	
    var body: some View {
		AlbumView(session: session, album: album)
//        Text("Hello World")
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#if DEBUG
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
