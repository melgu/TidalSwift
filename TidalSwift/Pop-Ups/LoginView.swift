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
	@ObservedObject var loginInfo: LoginInfo
	
	@State var username: String = ""
	@State var password: String = ""
	@State var authorization: Authorization = ""
	@State var countryCode: String = ""
	@State var userId: String = ""
	@State var quality: AudioQuality = .hifi
	
	var body: some View {
		VStack {
			Image("Icon")
			Text("TidalSwift")
				.font(.largeTitle)
			
			Group {
//				TextField("Username", text: $username)
//				SecureField("Password", text: $password, onCommit: login)
				
				SecureField("Authorization", text: $authorization)
				TextField("Country Code", text: $countryCode)
				SecureField("User ID", text: $userId)
			}
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
		guard let userId = Int(userId) else { return }
		appDelegate?.login(username: username, password: password, authorization: authorization, countryCode: countryCode, userId: userId, quality: quality)
	}
}
