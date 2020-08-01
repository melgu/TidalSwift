//
//  Featured.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation

extension Session {
	public func getFeatured() -> [FeaturedItem]? {
		let url = URL(string: "\(config.apiLocation)/promotions")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Featured failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var featuredResponse: FeaturedItems?
		do {
			featuredResponse = try customJSONDecoder().decode(FeaturedItems.self, from: content)
		} catch {
			displayError(title: "Featured failed (JSON Parse Error)", content: "\(error)")
		}
		
		return featuredResponse?.items
	}

	public func getMoods() -> [Mood]? {
		let url = URL(string: "\(config.apiLocation)/moods")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Mood Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var moodsResponse: [Mood]?
		do {
			moodsResponse = try customJSONDecoder().decode([Mood].self, from: content)
		} catch {
			displayError(title: "Mood Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return moodsResponse
	}

	public func getMoodPlaylists(moodPath: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/moods/\(moodPath)/playlists")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var moodPlaylists: Playlists?
		do {
			moodPlaylists = try customJSONDecoder().decode(Playlists.self, from: content)
		} catch {
			displayError(title: "Genre Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return moodPlaylists?.items
	}
	
	// TODO: There's more to moods and/or genres than playlists
	
	public func getGenres() -> [Genre]? { // Overview over all Genres
		let url = URL(string: "\(config.apiLocation)/genres")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Overview failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresResponse: [Genre]?
		do {
			genresResponse = try customJSONDecoder().decode([Genre].self, from: content)
		} catch {
			displayError(title: "Genre Overview failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresResponse
	}
	
	// Haven't found Artists in there yet, so only Tracks, Albums & Playlists
	
	public func getGenreTracks(genrePath: String) -> [Track]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genrePath)/tracks")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Tracks failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genreTracks: Tracks?
		do {
			genreTracks = try customJSONDecoder().decode(Tracks.self, from: content)
		} catch {
			displayError(title: "Genre Tracks failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genreTracks?.items
	}
	
	public func getGenreAlbums(genreName: String) -> [Album]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genreName)/albums")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Albums failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresAlbums: Albums?
		do {
			genresAlbums = try customJSONDecoder().decode(Albums.self, from: content)
		} catch {
			displayError(title: "Genre Albums failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresAlbums?.items
	}
	
public 	func getGenrePlaylists(genreName: String) -> [Playlist]? {
		let url = URL(string: "\(config.apiLocation)/genres/\(genreName)/playlists")!
		let response = Network.get(url: url, parameters: sessionParameters)
		
		guard let content = response.content else {
			displayError(title: "Genre Playlists failed (HTTP Error)", content: "Status Code: \(response.statusCode ?? -1)")
			return nil
		}
		
		var genresPlaylists: Playlists?
		do {
			genresPlaylists = try customJSONDecoder().decode(Playlists.self, from: content)
		} catch {
			displayError(title: "Genre Playlists failed (JSON Parse Error)", content: "\(error)")
		}
		
		return genresPlaylists?.items
	}
}
