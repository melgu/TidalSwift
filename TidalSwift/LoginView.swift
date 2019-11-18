//
//  LoginView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

final class LoginInfo: ObservableObject {
	@Published var showModal = false
	@Published var wrongLogin = false
}

struct LoginView: View {
	@State var username: String = ""
	@State var password: String = ""
	@State var quality: AudioQuality = .hifi
	
	@EnvironmentObject var loginInfo: LoginInfo
	
	var body: some View {
		VStack {
			Image("Icon")
			Text("TidalSwift")
				.font(.largeTitle)
			
			TextField("Username", text: $username)
				.frame(width: 200)
			SecureField("Password", text: $password, onCommit: login)
				.frame(width: 200)
			
			Picker(selection: $quality, label: Text("Quality")) {
				Text("Master").tag(AudioQuality.master)
				Text("HiFi").tag(AudioQuality.hifi)
				Text("High").tag(AudioQuality.high)
				Text("Low").tag(AudioQuality.low)
			}
			
			Text(loginInfo.wrongLogin ? "Wrong Login Credentials" : " ")
				.foregroundColor(.red)
			
			Button(action: login) {
				Text("Login")
			}
		}
		.textFieldStyle(RoundedBorderTextFieldStyle())
		.padding()
	}
	
	func login() {
		print("Login \(username) : \(password)")
		unowned let appDelegate = NSApp.delegate as? AppDelegate
		appDelegate?.login(username: username, password: password, quality: quality)
	}
}

//struct LoginView_Previews: PreviewProvider {
//	static var previews: some View {
//		LoginView()
//	}
//}
