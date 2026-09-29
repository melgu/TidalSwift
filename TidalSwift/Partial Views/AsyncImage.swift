//
//  AsyncImage.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 28.09.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

import SwiftUI

/// Replaces `SwiftUI.AsyncImage` so every image in the app works in lazy grids and lists.
///
/// `SwiftUI.AsyncImage` cancels its download when the view scrolls out of sight, keeps the
/// resulting cancellation error as its phase and never retries for the same URL.
/// Scrolling fast therefore leaves images missing for good. This version restarts
/// the download whenever the view appears again and keeps decoded images in memory.
/// It always shows the image resizable and scaled to fit, with a rectangle as placeholder.
struct AsyncImage: View {
	private enum Phase {
		case empty
		case success(Image)
		case failure
	}

	let url: URL

	@State private var task: Task<Void, Never>? = nil
	@State private var phase: Phase = .empty

	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		Group {
			switch phase {
			case .success(let image): image.resizable().scaledToFit()
			case .failure: Rectangle()
			case .empty: Rectangle()
					.overlay {
						// The rectangle is filled with the primary color, so the spinner needs the opposite color scheme to be visible on it
						ProgressView()
							.controlSize(.small)
							.environment(\.colorScheme, colorScheme == .dark ? .light : .dark)
					}
			}
		}
		.onAppear {
			// Covers the first appearance as well as loads that failed or were cancelled by disappearing
			if case .success = phase { return }
			load()
		}
		.onChange(of: url) { _, _ in
			load()
		}
		.onDisappear {
			task?.cancel()
		}
	}

	private func load() {
		self.task?.cancel()
		
		// Synchronously set cached image if available
		if let cached = ImageLoader.shared.cachedImage(for: url) {
			self.phase = .success(cached)
			return
		}
		phase = .empty
		
		// Asynchronously load image
		self.task = Task {
			var attempt = 0
			while !Task.isCancelled {
				if let image = await ImageLoader.shared.image(from: url) {
					guard !Task.isCancelled else { return }
					self.phase = .success(image)
					return
				}
				// Real network errors get a few delayed retries; cancellation ends the task and the next appearance starts over
				attempt += 1
				guard attempt < 3 else { break }
				try? await Task.sleep(for: .seconds(attempt))
			}
			guard !Task.isCancelled else { return }
			self.phase = .failure
		}
	}
}

private final class ImageLoader {
	static let shared = ImageLoader()

	private let cache = NSCache<NSURL, PlatformImage>()
	
	typealias ImageTask = Task<Image?, Never>
	private var tasks: [URL: ImageTask] = [:]

	private init() {
		cache.countLimit = 500
	}

	func cachedImage(for url: URL) -> Image? {
		guard let platformImage = cache.object(forKey: url as NSURL) else {
			return nil
		}
		return Image(platformImage: platformImage)
	}

	func image(from url: URL) async -> Image? {
		if let task = tasks[url] {
			return await task.value
		} else {
			let task = ImageTask {
				do {
					let (data, response) = try await URLSession.shared.data(from: url)
					if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
						return nil
					}
					guard let image = PlatformImage(data: data) else {
						return nil
					}
					cache.setObject(image, forKey: url as NSURL)
					return Image(platformImage: image)
				} catch {
					return nil
				}
			}
			tasks[url] = task
			defer { tasks[url] = nil }
			return await task.value
		}
	}
}

// MARK: - Platform Image

#if canImport(AppKit)
private typealias PlatformImage = NSImage

private extension Image {
	init(platformImage: PlatformImage) {
		self.init(nsImage: platformImage)
	}
}
#else
private typealias PlatformImage = UIImage

private extension Image {
	init(platformImage: PlatformImage) {
		self.init(uiImage: platformImage)
	}
}
#endif
