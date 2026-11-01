//
//  TidalServer.swift
//  TidalSwiftCLI
//
//  Created by Melvin Gundlach on 01.11.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import Foundation
import MCP
import TidalSwiftLib

private let instructions = """
	Tools for the user's Tidal account. Items are given as Tidal links (tidal.com/browse/…), \
	playlist UUIDs, or bare IDs together with their type, as tracks, albums, artists and videos share one number space. \
	The IDs and URLs in results can be passed on to other tools. Playlist positions start at 1, as show_playlist lists them. \
	If the account isn't logged in, a tool answers with a link the user has to open to log in.
	"""

/// The MCP server over stdin and stdout. Stdout carries only protocol messages, so nothing else may print to it.
@MainActor
final class TidalServer {
	private struct PendingLogin {
		let url: URL
		let expiration: Date
		let task: Task<Session, Error>
	}
	
	private let server = Server(
		name: "tidal",
		version: "1.0.0",
		title: "Tidal",
		instructions: instructions,
		capabilities: .init(tools: .init(listChanged: false))
	)
	
	private var session: Session?
	private var pendingLogin: PendingLogin?
	/// Asking the user to log in, which further calls wait for instead of asking again
	private var loginPrompt: Task<Session, Error>?
	private var elicitation: Client.Capabilities.Elicitation?
	
	func run() async throws {
		await server.withMethodHandler(ListTools.self) { _ in
			ListTools.Result(tools: tools)
		}
		await server.withMethodHandler(CallTool.self) { [self] parameters in
			try await call(parameters)
		}
		try await server.start(transport: StdioTransport()) { [self] _, capabilities in
			await setElicitation(capabilities.elicitation)
		}
		await server.waitUntilCompleted()
	}
	
	/// Failures of the tool itself go to the model as results it can act on. Protocol errors, like an unknown tool, are thrown.
	private func call(_ parameters: CallTool.Parameters) async throws -> CallTool.Result {
		do {
			let session = try await loggedInSession()
			let progress = progressReporter(token: parameters._meta?.progressToken)
			defer { progress.finish() }
			let text = try await callTool(parameters.name, arguments: ToolArguments(parameters.arguments), session: session) {
				progress.yield($0)
			}
			return CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)])
		} catch let error as CLIError {
			return failure(error.description)
		} catch let error as MCPError {
			throw error
		} catch {
			return failure(error.localizedDescription)
		}
	}
	
	private func failure(_ message: String) -> CallTool.Result {
		CallTool.Result(content: [.text(text: message, annotations: nil, _meta: nil)], isError: true)
	}
	
	// MARK: - Login
	
	private func setElicitation(_ elicitation: Client.Capabilities.Elicitation?) {
		self.elicitation = elicitation
	}
	
	/// The stored login, or one finished since the last call. Otherwise starts a login and asks the user
	/// to approve it through the client, or, if the client can't ask, fails with its link.
	private func loggedInSession() async throws -> Session {
		if let session {
			return session
		}
		let stored = makeSession()
		if stored.loadSession() {
			session = stored
			return stored
		}
		
		if let loginPrompt {
			return try await loginPrompt.value
		}
		let login = try await startLogin()
		guard let elicitation else {
			throw loginRequired(login)
		}
		let prompt = Task {
			defer { loginPrompt = nil }
			return try await askToLogIn(login, elicitation: elicitation)
		}
		loginPrompt = prompt
		return try await prompt.value
	}
	
	/// Shows the link in the client and waits until the login is approved
	private func askToLogIn(_ login: PendingLogin, elicitation: Client.Capabilities.Elicitation) async throws -> Session {
		let expiration = login.expiration.formatted(date: .omitted, time: .shortened)
		let elicitationId = UUID().uuidString
		let result: CreateElicitation.Result
		do {
			if elicitation.url != nil {
				result = try await server.requestElicitation(
					message: "Log in to Tidal by approving this device on the page that opens. The link works until \(expiration).",
					url: login.url.absoluteString,
					elicitationId: elicitationId
				)
			} else {
				// Form mode can only show text, so the link is part of the message
				result = try await server.requestElicitation(
					message: "Open \(login.url.absoluteString) and approve the login to Tidal before \(expiration), then continue here.",
					requestedSchema: .init()
				)
			}
		} catch {
			// The client claimed support but couldn't ask, so the model passes the link on instead
			throw loginRequired(login)
		}
		
		guard result.action == .accept else {
			throw CLIError("The user didn't log in to Tidal. Calling a tool again asks again, or run `tidal login` in a terminal.")
		}
		let session = try await login.task.value
		if elicitation.url != nil {
			try? await server.notify(ElicitationCompleteNotification.message(.init(elicitationId: elicitationId)))
		}
		return session
	}
	
	private func loginRequired(_ login: PendingLogin) -> CLIError {
		CLIError("""
			Not logged in to Tidal. Ask the user to open \(login.url.absoluteString) and approve the login \
			before \(login.expiration.formatted(date: .omitted, time: .shortened)), then call the tool again. \
			Running `tidal login` in a terminal works as well.
			""")
	}
	
	/// Starts the device login, or returns the one still waiting for approval
	private func startLogin() async throws -> PendingLogin {
		if let pendingLogin, pendingLogin.expiration > .now {
			return pendingLogin
		}
		pendingLogin?.task.cancel()
		pendingLogin = nil
		
		// The task keeps waiting for the approval after handing out the link, so a later call finds the session
		let newSession = makeSession()
		var task: Task<Session, Error>?
		let link = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(url: URL, expiration: Date), Error>) in
			task = Task { @MainActor in
				var linkContinuation: CheckedContinuation? = continuation
				defer { linkContinuation?.resume(throwing: CLIError("Couldn't start the login")) }
				for await state in newSession.startAuthorization() {
					switch state {
					case .waiting:
						break
					case .pending(let url, let expiration):
						linkContinuation?.resume(returning: (url, expiration))
						linkContinuation = nil
					case .success:
						newSession.saveConfig()
						guard newSession.loadSession() else {
							throw CLIError("Logged in, but couldn't load the account")
						}
						return newSession
					case .failure(let error):
						let error = CLIError("Login failed: \(error.localizedDescription)")
						linkContinuation?.resume(throwing: error)
						linkContinuation = nil
						throw error
					}
				}
				throw CLIError("Login stopped")
			}
		}
		guard let task else {
			throw CLIError("Couldn't start the login")
		}
		let login = PendingLogin(url: link.url, expiration: link.expiration, task: task)
		pendingLogin = login
		
		Task {
			let result = await task.result
			// Only if no newer login replaced this one in the meantime
			guard pendingLogin?.task == task else { return }
			pendingLogin = nil
			if case .success(let session) = result {
				self.session = session
			}
		}
		return login
	}
	
	// MARK: - Progress
	
	/// Sends progress notifications in order, if the client asked for them with a token
	private func progressReporter(token: ProgressToken?) -> AsyncStream<String>.Continuation {
		let (stream, continuation) = AsyncStream<String>.makeStream()
		guard let token else {
			continuation.finish()
			return continuation
		}
		Task { [server] in
			var step = 0.0
			for await message in stream {
				step += 1
				try? await server.notify(ProgressNotification.message(.init(progressToken: token, progress: step, message: message)))
			}
		}
		return continuation
	}
}
