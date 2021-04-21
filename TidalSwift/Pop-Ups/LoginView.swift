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
	@ObservedObject var viewState: ViewState
	
	let session: Session
	let player: Player
	
	@State var accessToken: String = ""
	@State var refreshToken: String = ""
	@State var offlineAudioQuality: AudioQuality = .hifi
	@State var audioUrlType: AudioUrlType = .offline
	
	var body: some View {
		ScrollView {
			VStack {
				Image("Icon")
				Text("TidalSwift")
					.font(.largeTitle)
				
				TabView {
					deviceLogin
						.tabItem { Text("Device Login") }
					
					authLogin
						.tabItem { Text("Authorization") }
				}
				.frame(minWidth: 300)
				
				Picker(selection: $offlineAudioQuality, label: Text("Offline Audio Quality")) {
//					Text("Master").tag(AudioQuality.master)
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
	}
	
	var deviceLogin: some View {
		Text("Coming soon...")
	}
	
	var authLogin: some View {
		VStack(alignment: .leading) {
			SecureField("Authorization / Access Token", text: $accessToken)
			
			Text("In the form: Bearer ABC123…")
				.foregroundColor(.secondary)
			
			SecureField("Optional Refresh Token", text: $refreshToken)
			
			Picker(selection: $audioUrlType, label: Text("Audio URL Type"), content: {
				Text("Offline").tag(AudioUrlType.offline)
				Text("Streaming").tag(AudioUrlType.streaming)
			})
			Text("When choosing Offline, TidalSwift won't stop playback on official clients, but does not work with TV athorization details.")
				.foregroundColor(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
	
	func login() {
		session.config.urlType = audioUrlType
		DispatchQueue.global().async {
			let loginSuccessful = session.setAccessToken(accessToken, refreshToken: refreshToken)
			DispatchQueue.main.async {
				if loginSuccessful {
					loginInfo.wrongLogin = false
					loginInfo.showModal = false
					session.saveConfig()
					session.saveSession()
					player.setAudioQuality(to: offlineAudioQuality)
					viewState.push(view: TidalSwiftView(viewType: .favoriteTracks))
				} else {
					loginInfo.wrongLogin = true
				}
			}
		}
	}
}
