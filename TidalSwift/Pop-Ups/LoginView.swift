//
//  LoginView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import Combine
import TidalSwiftLib

final class LoginInfo: ObservableObject {
	@Published var showModal = false
}

struct LoginView: View {
	@ObservedObject var loginInfo: LoginInfo
	@ObservedObject var viewState: ViewState
	
	let session: Session
	let player: Player
	
	@State var wrongLogin: Bool = false
	@State var cancellables = Set<AnyCancellable>()
	@State var authState: Session.AuthorizationState = .waiting
	@State var counter = 300
	let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	@State var refreshToken: String = ""
	@State var clientID: String = ""
	@State var offlineAudioQuality: AudioQuality = .high
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
			}
			.textFieldStyle(RoundedBorderTextFieldStyle())
			.padding()
		}
	}
	
	var deviceLogin: some View {
		VStack {
			switch authState {
			case .waiting:
				Text("Login mechinism, which works via the webbrowser")
			case .pending(loginUrl: let loginUrl, expiration: _):
				Button {
					NSWorkspace.shared.open(loginUrl)
				} label: {
					Text("Open Browser")
				}
				
				if counter > 0 {
					Text("Time remaining: \(counter)")
						.onReceive(timer, perform: { _ in
							counter -= 1
						})
				} else {
					Text("Time expired")
				}
			case .success:
				EmptyView()
			case .failure(_):
				Text("Something went wrong")
					.foregroundColor(.red)
			}
			
			qualityPicker
			
			Button(action: startAuthorization) {
				Text("Login")
			}
		}
		.padding()
	}
	
	var authLogin: some View {
		VStack {
			SecureField("Refresh Token", text: $refreshToken)
			
			TextField("Client ID", text: $clientID)
			
			Picker(selection: $audioUrlType, label: Text("Audio URL Type"), content: {
				Text("Offline").tag(AudioUrlType.offline)
				Text("Streaming").tag(AudioUrlType.streaming)
			})
			Text("When choosing Offline, TidalSwift won't stop playback on official clients, but does not work with TV authorization details.")
				.foregroundColor(.secondary)
				.fixedSize(horizontal: false, vertical: true)
			
			qualityPicker
			
			if wrongLogin {
				Text("Wrong Login Credentials")
					.foregroundColor(.red)
			}
			
			Button(action: setAuthorization) {
				Text("Login")
			}
		}
		.padding()
	}
	
	var qualityPicker: some View {
		Picker(selection: $offlineAudioQuality, label: Text("Offline Audio Quality")) {
			ForEach(AudioQuality.allCases) { quality in
				Text(quality.title).tag(quality)
			}
		}
	}
	
	func startAuthorization() {
		cancellables.removeAll()
		
		let subject = session.startAuthorization()
			.receive(on: DispatchQueue.main)
		
		subject
			.assign(to: \.authState, on: self)
			.store(in: &cancellables)
		
		subject
			.sink { value in
				switch value {
				case .waiting:
					wrongLogin = false
				case .pending(loginUrl: let loginUrl, expiration: _):
					counter = 300
					NSWorkspace.shared.open(loginUrl)
				case .success:
					successfulLogin(audioUrlType: .streaming)
				case .failure(_):
					wrongLogin = true
				}
			}
			.store(in: &cancellables)
	}
	
	func setAuthorization() {
		session.config.urlType = audioUrlType
		Task {
			let loginSuccessful = await session.login(refreshToken: refreshToken, clientID: clientID)
			if loginSuccessful {
				successfulLogin(audioUrlType: audioUrlType)
			} else {
				wrongLogin = true
			}
		}
	}
	
	func successfulLogin(audioUrlType: AudioUrlType) {
		wrongLogin = false
		loginInfo.showModal = false
		session.config.urlType = audioUrlType
		session.saveConfig()
		session.saveSession()
		session.scheduleAccessTokenRefresh()
		player.setAudioQuality(to: offlineAudioQuality)
		viewState.push(view: TidalSwiftView(viewType: .favoriteTracks))
	}
}
