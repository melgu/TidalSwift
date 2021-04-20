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
	
	@State var authorization: String = ""
	@State var offlineAudioQuality: AudioQuality = .hifi
	
	var body: some View {
		VStack {
			Image("Icon")
			Text("TidalSwift")
				.font(.largeTitle)
			
			VStack(alignment: .leading) {
				SecureField("Authorization", text: $authorization)
				Text("In the form: Bearer ABC123…")
			}
			.frame(width: 300)
			
			Picker(selection: $offlineAudioQuality, label: Text("Offline Audio Quality")) {
//				Text("Master").tag(AudioQuality.master)
				Text("HiFi").tag(AudioQuality.hifi)
				Text("High").tag(AudioQuality.high)
				Text("Low").tag(AudioQuality.low)
			}
			
			Text(loginInfo.wrongLogin ? "Wrong Login Credentials" : " ")
				.foregroundColor(.red)
			
			Text("A restart of the app is required after login.")
				.foregroundColor(.gray)
			
			Button(action: login) {
				Text("Login")
			}
		}
		.textFieldStyle(RoundedBorderTextFieldStyle())
		.padding()
	}
	
	func login() {
		unowned let appDelegate = NSApp.delegate as? AppDelegate
		appDelegate?.login(authorization: authorization, offlineAudioQuality: offlineAudioQuality)
	}
}
