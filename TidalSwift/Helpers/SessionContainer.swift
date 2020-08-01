//
//  SessionContainer.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 28.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Foundation
import Combine
import TidalSwiftLib

final class SessionContainer: ObservableObject {
	@Published var session: Session
	@Published var player: Player
	
	init(session: Session, player: Player) {
		self.session = session
		self.player = player
	}
}
