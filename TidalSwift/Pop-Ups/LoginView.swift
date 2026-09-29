//
//  LoginView.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 16.10.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

@Observable
final class LoginInfo {
	var showModal = false
}

struct LoginView: View {
	let loginInfo: LoginInfo
	let viewState: ViewState
	
	let session: Session
	
	@Environment(\.openURL) private var openURL
	
	@State private var authorizationTask: Task<Void, Never>?
	@State private var authState: Session.AuthorizationState = .waiting
	@State private var counter = 300
	
	@State private var refreshToken: String = ""
	@State private var clientID: String = ""
	@State private var loginErrorMessage: String?
	
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
		.onDisappear {
			authorizationTask?.cancel()
		}
	}
	
	private var deviceLogin: some View {
		VStack {
			switch authState {
			case .waiting:
				Text("Login mechinism, which works via the webbrowser")
			case .pending(loginUrl: let loginUrl, expiration: _):
				Button {
					openURL(loginUrl)
				} label: {
					Text("Open Browser")
				}
				
				if counter > 0 {
					Text("Time remaining: \(counter)")
						.task {
							while counter > 0 {
								do {
									try await Task.sleep(for: .seconds(1))
								} catch {
									return
								}
								counter -= 1
							}
						}
				} else {
					Text("Time expired")
				}
			case .success:
				EmptyView()
			case .failure(_):
				Text("Something went wrong")
					.foregroundColor(.red)
			}
			
			Button(action: startAuthorization) {
				Text("Login")
			}
		}
		.padding()
	}
	
	private var authLogin: some View {
		VStack {
			SecureField("Refresh Token", text: $refreshToken)
			
			TextField("Client ID", text: $clientID)
			
			if let loginErrorMessage {
				Text(loginErrorMessage)
					.foregroundColor(.red)
			}

			Button(action: setAuthorization) {
				Text("Login")
			}
		}
		.padding()
	}
	
	private func startAuthorization() {
		authorizationTask?.cancel()
		authorizationTask = Task {
			for await state in session.startAuthorization() {
				authState = state
				switch state {
				case .waiting:
					break
				case .pending(loginUrl: let loginUrl, expiration: _):
					counter = 300
					openURL(loginUrl)
				case .success:
					successfulLogin()
				case .failure(_):
					break
				}
			}
		}
	}
	
	private func setAuthorization() {
		Task {
			do {
				try await session.login(refreshToken: refreshToken, clientID: clientID)
				successfulLogin()
			} catch SessionError.invalidCredentials {
				loginErrorMessage = "Wrong Login Credentials"
			} catch SessionError.network {
				loginErrorMessage = "Couldn't reach Tidal. Check your internet connection."
			} catch {
				loginErrorMessage = "Login failed"
			}
		}
	}
	
	private func successfulLogin() {
		loginErrorMessage = nil
		loginInfo.showModal = false
		session.saveConfig()
		session.saveSession()
		viewState.push(view: TidalSwiftView(viewType: .favoriteTracks))
	}
}
