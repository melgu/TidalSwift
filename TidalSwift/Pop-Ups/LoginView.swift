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
	/// Set when adding the second login, instead of logging in for the first time
	var addingKind: LoginKind?
	/// The session's logins, for views and menus, as the session isn't observable
	var loginKinds: Set<LoginKind> = []
}

extension LoginKind {
	var name: String {
		switch self {
		case .device: "Dolby Atmos"
		case .pkce: "Hi-Res"
		}
	}
	
	var advantages: [String] {
		switch self {
		case .device: ["High: FLAC 16 bit / 44.1 kHz", "Dolby Atmos"]
		case .pkce: ["All qualities: Low, High and Max (FLAC up to 24 bit / 192 kHz)"]
		}
	}
	
	/// What the other login makes up for
	var limitations: [String] {
		switch self {
		case .device: ["No Hi-Res", "No Low qualities, plays High instead"]
		case .pkce: ["No Dolby Atmos, tracks play in stereo"]
		}
	}
	
	var loginSteps: String {
		switch self {
		case .device: "Confirm the login in the browser."
		case .pkce: "Log in in the browser, then copy the address of the error page Tidal shows into TidalSwift."
		}
	}
	
	var other: LoginKind {
		self == .device ? .pkce : .device
	}
}

struct LoginView: View {
	let loginInfo: LoginInfo
	let viewState: ViewState
	
	let session: Session
	
	@Environment(\.openURL) private var openURL
	@Environment(FavoritesState.self) private var favoritesState
	
	/// The kind picked for the first login
	@State private var chosenKind: LoginKind?
	
	@State private var authorizationTask: Task<Void, Never>?
	@State private var authState: Session.AuthorizationState = .waiting
	@State private var counter = 300
	
	@State private var refreshToken: String = ""
	@State private var clientID: String = ""
	@State private var loginErrorMessage: String?
	
	@State private var pkceAuthorization: PKCEAuthorization?
	@State private var pkceRedirectUrl: String = ""
	@State private var pkceErrorMessage: String?
	@State private var isFinishingPKCE = false
	
	private var kind: LoginKind? {
		loginInfo.addingKind ?? chosenKind
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 16) {
				Image("Icon")
				Text("TidalSwift")
					.font(.largeTitle)
				
				if let kind {
					flow(for: kind)
				} else {
					choice
				}
			}
			.textFieldStyle(RoundedBorderTextFieldStyle())
			.padding()
		}
		.scrollBounceBehavior(.basedOnSize)
		// Without a login, the app is unusable behind the sheet. Adding the second login closes with Cancel, which Escape triggers.
		.interactiveDismissDisabled()
		#if os(macOS)
		.frame(minWidth: 560, minHeight: 520)
		#endif
		.onDisappear {
			authorizationTask?.cancel()
			loginInfo.addingKind = nil
		}
	}
	
	// MARK: - Choice
	
	private var choice: some View {
		VStack(spacing: 12) {
			Text("Choose a Login")
				.font(.title2)
			
			HStack(alignment: .top, spacing: 12) {
				ForEach(LoginKind.allCases, id: \.self) { kind in
					VStack(alignment: .leading, spacing: 8) {
						description(of: kind)
						Spacer(minLength: 0)
						Button("Log in with \(kind.name)") {
							chosenKind = kind
						}
						.frame(maxWidth: .infinity)
					}
					.padding()
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
					.background(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
				}
			}
			.fixedSize(horizontal: false, vertical: true)
			
			Text("After logging in, you can add the other login under Account in the menu bar, to get both Hi-Res and Dolby Atmos.")
				.font(.callout)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
			
			DisclosureGroup("Log in with a Refresh Token") {
				authLogin
			}
		}
	}
	
	/// When adding the second login, the existing one makes up for its limitations, so only what it adds counts
	private func description(of kind: LoginKind, isAdding: Bool = false) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			if !isAdding {
				Text(kind.name)
					.font(.headline)
			}
			ForEach(kind.advantages, id: \.self) { advantage in
				Label(advantage, systemImage: "checkmark.circle")
			}
			if !isAdding {
				ForEach(kind.limitations, id: \.self) { limitation in
					Label(limitation, systemImage: "xmark.circle")
						.foregroundStyle(.secondary)
				}
			}
			if isAdding {
				Text("Your \(kind.other.name) login stays. TidalSwift uses each login for what it does best.")
					.font(.callout)
					.foregroundStyle(.secondary)
			}
			Text(kind.loginSteps)
				.font(.callout)
				.foregroundStyle(.secondary)
		}
		.fixedSize(horizontal: false, vertical: true)
	}
	
	// MARK: - Login
	
	private func flow(for kind: LoginKind) -> some View {
		VStack(spacing: 12) {
			Text(loginInfo.addingKind == nil ? "\(kind.name) Login" : "Add \(kind.name) Login")
				.font(.title2)
			
			description(of: kind, isAdding: loginInfo.addingKind != nil)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			switch kind {
			case .device:
				deviceLogin
			case .pkce:
				pkceLogin
			}
			
			Button(loginInfo.addingKind == nil ? "Back" : "Cancel") {
				authorizationTask?.cancel()
				authState = .waiting
				pkceAuthorization = nil
				pkceRedirectUrl = ""
				pkceErrorMessage = nil
				if loginInfo.addingKind == nil {
					chosenKind = nil
				} else {
					loginInfo.showModal = false
				}
			}
			// The sheet can't be dismissed, but adding the second login can be cancelled with Escape
			.keyboardShortcut(loginInfo.addingKind == nil ? nil : .cancelAction)
		}
	}
	
	private var deviceLogin: some View {
		VStack {
			switch authState {
			case .waiting:
				EmptyView()
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
			case .failure(let error):
				Text(message(for: error))
					.foregroundStyle(.red)
			}
			
			Button(action: startAuthorization) {
				Text("Login")
			}
		}
		.padding()
	}
	
	private var pkceLogin: some View {
		VStack {
			Button("Open Browser") {
				let authorization = session.startPKCEAuthorization()
				pkceAuthorization = authorization
				pkceErrorMessage = nil
				openURL(authorization.loginUrl)
			}
			
			TextField("Address of the Error Page", text: $pkceRedirectUrl)
				.disabled(pkceAuthorization == nil)
			
			if let pkceErrorMessage {
				Text(pkceErrorMessage)
					.foregroundStyle(.red)
			}
			
			Button(action: finishPKCEAuthorization) {
				Text("Login")
			}
			.disabled(pkceAuthorization == nil || pkceRedirectUrl.isEmpty || isFinishingPKCE)
		}
		.padding()
	}
	
	private var authLogin: some View {
		VStack {
			SecureField("Refresh Token", text: $refreshToken)
			
			TextField("Client ID", text: $clientID)
			
			if let loginErrorMessage {
				Text(loginErrorMessage)
					.foregroundStyle(.red)
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
	
	private func finishPKCEAuthorization() {
		guard let pkceAuthorization else { return }
		guard let redirectUrl = URL(string: pkceRedirectUrl.trimmingCharacters(in: .whitespacesAndNewlines)),
			  PKCEAuthorization.isRedirect(redirectUrl)
		else {
			pkceErrorMessage = "That's not the address of the error page"
			return
		}
		isFinishingPKCE = true
		Task {
			defer { isFinishingPKCE = false }
			do {
				try await session.finishPKCEAuthorization(pkceAuthorization, redirectUrl: redirectUrl)
				pkceErrorMessage = nil
				successfulLogin()
			} catch SessionError.invalidCredentials(let description) {
				pkceErrorMessage = description ?? "Tidal rejected the login. Open the browser again for a new one."
			} catch {
				pkceErrorMessage = message(for: error)
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
	
	private func message(for error: Error) -> String {
		switch error as? SessionError {
		case .differentAccount:
			"This is another Tidal account than the one you're logged in with."
		case .invalidCredentials(let description):
			description ?? "Tidal rejected the login."
		case .network:
			"Couldn't reach Tidal. Check your internet connection."
		default:
			error.localizedDescription
		}
	}
	
	private func successfulLogin() {
		loginErrorMessage = nil
		loginInfo.loginKinds = session.loginKinds
		session.saveConfig()
		favoritesState.refresh()
		let isFirstLogin = loginInfo.addingKind == nil
		loginInfo.addingKind = nil
		loginInfo.showModal = false
		if isFirstLogin {
			viewState.push(view: TidalSwiftView(viewType: .favoriteTracks))
		}
	}
}
