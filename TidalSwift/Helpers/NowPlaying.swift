//
//  NowPlaying.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 23.10.26.
//  Copyright © 2026 Melvin Gundlach. All rights reserved.
//

#if canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#else
import UIKit
private typealias PlatformImage = UIImage
#endif
import MediaPlayer
import TidalSwiftLib

/// Publishes the current track to the system's Now Playing info and receives its remote commands,
/// which is how the media keys, Control Center and headphone buttons reach the app
final class NowPlaying {
	private let session: Session
	private var artworkTrackID: Int?
	
	init(session: Session) {
		self.session = session
	}
	
	struct Commands {
		let play: @MainActor () -> Void
		let pause: @MainActor () -> Void
		let togglePlay: @MainActor () -> Void
		let next: @MainActor () -> Void
		let previous: @MainActor () -> Void
		let seek: @MainActor (Double) -> Void
	}
	
	func register(_ commands: Commands) {
		let center = MPRemoteCommandCenter.shared()
		// The handlers aren't guaranteed to be called on the main thread
		func add(_ command: MPRemoteCommand, _ action: @escaping @MainActor () -> Void) {
			command.addTarget { @Sendable _ in
				Task { @MainActor in action() }
				return .success
			}
		}
		add(center.playCommand, commands.play)
		add(center.pauseCommand, commands.pause)
		add(center.togglePlayPauseCommand, commands.togglePlay)
		add(center.nextTrackCommand, commands.next)
		add(center.previousTrackCommand, commands.previous)
		center.changePlaybackPositionCommand.addTarget { @Sendable event in
			guard let event = event as? MPChangePlaybackPositionCommandEvent else {
				return .commandFailed
			}
			let position = event.positionTime
			Task { @MainActor in commands.seek(position) }
			return .success
		}
	}
	
	func update(track: Track) {
		var info: [String: Any] = [
			MPMediaItemPropertyTitle: track.title,
			MPMediaItemPropertyArtist: track.artists.formArtistString(),
			MPMediaItemPropertyAlbumTitle: track.album.title,
			MPMediaItemPropertyPlaybackDuration: Double(track.duration),
			MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
			MPNowPlayingInfoPropertyPlaybackRate: 0.0,
		]
		// Keep the artwork while the same track is set again, e.g. after a failed load
		if artworkTrackID == track.id, let artwork = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] {
			info[MPMediaItemPropertyArtwork] = artwork
		}
		MPNowPlayingInfoCenter.default().nowPlayingInfo = info
		
		guard artworkTrackID != track.id, let url = track.getCoverUrl(session: session, resolution: 640) else {
			return
		}
		artworkTrackID = track.id
		Task {
			guard let (data, _) = try? await URLSession.shared.data(from: url),
				  let artwork = Self.artwork(from: data),
				  artworkTrackID == track.id,
				  var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
				return
			}
			info[MPMediaItemPropertyArtwork] = artwork
			MPNowPlayingInfoCenter.default().nowPlayingInfo = info
		}
	}
	
	// The request handler is called off the main thread, so the artwork is built outside the main actor
	nonisolated private static func artwork(from data: Data) -> MPMediaItemArtwork? {
		guard let image = PlatformImage(data: data) else {
			return nil
		}
		return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
	}
	
	func update(playing: Bool, elapsed: Double) {
		let center = MPNowPlayingInfoCenter.default()
		if var info = center.nowPlayingInfo {
			info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
			info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
			center.nowPlayingInfo = info
		}
		center.playbackState = playing ? .playing : .paused
	}
	
	func clear() {
		artworkTrackID = nil
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
		MPNowPlayingInfoCenter.default().playbackState = .stopped
	}
}
