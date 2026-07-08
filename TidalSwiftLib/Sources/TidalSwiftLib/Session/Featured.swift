//
//  Featured.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func featured() async -> [FeaturedItem]? {
		let url = URL(string: "\(AuthInformation.APILocation)/promotions")!
		do {
			let response: FeaturedItems = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}

	public func moods() async -> [Mood]? {
		let url = URL(string: "\(AuthInformation.APILocation)/moods")!
		do {
			let response: [Mood] = try await get(url: url, parameters: sessionParameters)
			return response
		} catch {
			return nil
		}
	}

	public func moodPlaylists(moodPath: String) async -> [Playlist]? {
		let url = URL(string: "\(AuthInformation.APILocation)/moods/\(moodPath)/playlists")!
		do {
			let response: Playlists = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}
	
	// TODO: There's more to moods and/or genres than playlists
	
	public func genres() async -> [Genre]? { // Overview over all Genres
		let url = URL(string: "\(AuthInformation.APILocation)/genres")!
		do {
			let response: [Genre] = try await get(url: url, parameters: sessionParameters)
			return response
		} catch {
			return nil
		}
	}
	
	// Haven't found Artists in there yet, so only Tracks, Albums & Playlists
	
	public func genreTracks(genrePath: String) async -> [Track]? {
		let url = URL(string: "\(AuthInformation.APILocation)/genres/\(genrePath)/tracks")!
		do {
			let response: Tracks = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func genreAlbums(genreName: String) async -> [Album]? {
		let url = URL(string: "\(AuthInformation.APILocation)/genres/\(genreName)/albums")!
		do {
			let response: Albums = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}
	
	public func genrePlaylists(genreName: String) async -> [Playlist]? {
		let url = URL(string: "\(AuthInformation.APILocation)/genres/\(genreName)/playlists")!
		do {
			let response: Playlists = try await get(url: url, parameters: sessionParameters)
			return response.items
		} catch {
			return nil
		}
	}
}
