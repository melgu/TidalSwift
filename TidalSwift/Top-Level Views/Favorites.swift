//
//  Favorites.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 21.08.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import SwiftUI
import TidalSwiftLib

private func bestCoverURL(for track: Track, session: Session, preferred sizes: [Int]) -> URL? {
    for size in sizes {
        if let url = track.getCoverUrl(session: session, resolution: size) {
            return url
        }
    }
    return nil
}

let PICKERWIDTH: CGFloat = 580

struct ReverseButton: View {
	@Binding var reversed: Bool
	
	var body: some View {
		Button {
			reversed.toggle()
		} label: {
			if reversed {
                
				Image(systemName: "chevron.down")
                    .imageScale(.medium).frame(width:15, height: 15)
			} else {
				Image(systemName: "chevron.up")
                    .imageScale(.medium).frame(width:15, height: 15)
			}
		}
	}
}

struct FavoritePlaylists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		List {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Playlists")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
                    
					LoadingSpinner()
					
						Picker(selection: $sortingState.favoritePlaylistSorting, label: Spacer(minLength: 0)) {
							Text("Added").tag(PlaylistSorting.dateAdded)
							Text("Title").tag(PlaylistSorting.title)
							Text("Last Updated").tag(PlaylistSorting.lastUpdated)
							Text("Created").tag(PlaylistSorting.created)
							Text("Type").tag(PlaylistSorting.type)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
                        .contentMargins(0)

						ReverseButton(reversed: $sortingState.favoritePlaylistReversed)
							
					
				}
				if let playlists = viewState.stack.last?.playlists {
					HStack {
						Text("\(playlists.count) \(playlists.count == 1 ? "Playlist" : "Playlists")")
						Spacer()
					}

					// Precompute ordered playlists once per render to avoid repeated work in subviews
					let orderedPlaylists = playlists
						.sortedPlaylists(by: sortingState.favoritePlaylistSorting)
						.reversed(sortingState.favoritePlaylistReversed)

					// Host grid in a lazy container to reduce upfront layout work
					LazyVStack(spacing: 0) {
						PlaylistGrid(playlists: orderedPlaylists, session: session, player: player)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteAlbums: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		List {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Albums")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
					LoadingSpinner()
					
						Picker(selection: $sortingState.favoriteAlbumSorting, label: Spacer(minLength: 0)) {
							Text("Added").tag(AlbumSorting.dateAdded)
							Text("Title").tag(AlbumSorting.title)
							Text("Artists").tag(AlbumSorting.artists)
							Text("Release Date").tag(AlbumSorting.releaseDate)
							Text("Duration").tag(AlbumSorting.duration)
							Text("Popularity").tag(AlbumSorting.popularity)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
                        .contentMargins(0)

						ReverseButton(reversed: $sortingState.favoriteAlbumReversed)
							
					
				}
				if let albums = viewState.stack.last?.albums {
					HStack {
						Text("\(albums.count) \(albums.count == 1 ? "Album" : "Albums")")
						Spacer()
					}
					AlbumGrid(albums: albums.sortedAlbums(by: sortingState.favoriteAlbumSorting).reversed(sortingState.favoriteAlbumReversed), showArtists: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteTracks: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	@AppStorage("SaveFavoritesOffline") public var saveFavoritesOffline = false
    @State private var hoveredTrackID: Int? = nil
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack {
					HStack {
						Text("Favorite Tracks")
							.font(.largeTitle)
							.lineLimit(1)
						Spacer()
						LoadingSpinner()
						if saveFavoritesOffline {
							Image(systemName: "cloud.fill")
								.resizable()
								.scaledToFit()
								.frame(width: 30)
								.onTapGesture {
									
									saveFavoritesOffline = false
									session.helpers.offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
						} else {
							Image(systemName: "cloud")
								.resizable()
								.scaledToFit()
								.frame(width: 30)
								.onTapGesture {
									
									saveFavoritesOffline = true
									session.helpers.offline.asyncSyncFavoriteTracks()
									viewState.refreshCurrentView()
								}
						}
						
							Picker(selection: $sortingState.favoriteTrackSorting, label: Spacer(minLength: 0)) {
								Text("Added").tag(TrackSorting.dateAdded)
								Text("Title").tag(TrackSorting.title)
								Text("Artists").tag(TrackSorting.artists)
								Text("Album").tag(TrackSorting.album)
								Text("Release Date").tag(TrackSorting.albumReleaseDate)
//								Text("Duration").tag(TrackSorting.duration)
								Text("Popularity").tag(TrackSorting.popularity)
                                
                                
							}
							.pickerStyle(SegmentedPickerStyle())
							.frame(width: PICKERWIDTH)
                            .contentMargins(0)
                            
                            ReverseButton(reversed: $sortingState.favoriteTrackReversed)
                              
							
						
					}
					if let tracks = viewState.stack.last?.tracks {
						HStack {
							Text("\(tracks.count) \(tracks.count == 1 ? "Track" : "Tracks")")
							Spacer()
						}
					}
				}
				.padding(.horizontal)
				
				if let tracks = viewState.stack.last?.tracks {
                    // Precompute ordered wrapped tracks once per render to reduce work in row bodies
                    let orderedWrapped = tracks
                        .sortedTracks(by: sortingState.favoriteTrackSorting)
                        .reversed(sortingState.favoriteTrackReversed)
                        .wrapped()

                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(orderedWrapped.enumerated()), id: \.element.track.id) { index, wrapped in
                            Divider()
                            HStack{
                                Text((index + 1).formatted())
                                TrackItemView(
                                    track: wrapped.track,
                                    session: session,
                                    player: player,
                                    isHovered: hoveredTrackID == wrapped.track.id,
                                    onHoverChange: { hovering in
                                        hoveredTrackID = hovering ? wrapped.track.id : nil
                                    },
                                    onRemovedFromFavorites: {
                                        viewState.refreshCurrentView()
                                    },
                                    onPressedPlay: {
                                        player.clearQueue()
                                        // Start the selected track now
                                        player.add(track: wrapped.track, .now)

                                        // Queue only the tracks after the selected one
                                        let remainder = orderedWrapped.dropFirst(index + 1)
                                        player.play()
                                        player.add(tracks: remainder.map { $0.track }, .next)
                                    },
                                    showCover: true,
                                    isAlbumView: false,
                                )
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal)
                        }
                    }
				}
				Spacer(minLength: 0)
			}
			.padding(.top)
		}
	}
}

struct FavoriteVideos: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		List {
			VStack(alignment: .leading) {
				HStack {
					Text("Favorite Videos")
						.font(.largeTitle)
						.lineLimit(1)
					Spacer()
					LoadingSpinner()
					ZStack(alignment: .trailing) {
						Picker(selection: $sortingState.favoriteVideoSorting, label: Spacer(minLength: 0)) {
							Text("Added").tag(VideoSorting.dateAdded)
							Text("Title").tag(VideoSorting.title)
							Text("Artists").tag(VideoSorting.artists)
							Text("Release Date").tag(VideoSorting.releaseDate)
							Text("Duration").tag(VideoSorting.duration)
							Text("Popularity").tag(VideoSorting.popularity)
						}
						.pickerStyle(SegmentedPickerStyle())
						.frame(width: PICKERWIDTH)
						.padding(.trailing, 32)

						ReverseButton(reversed: $sortingState.favoriteVideoReversed)
							.padding(.trailing, 4)
					}
				}
				if let videos = viewState.stack.last?.videos {
					HStack {
						Text("\(videos.count) \(videos.count == 1 ? "Video" : "Videos")")
						Spacer()
					}
					VideoGrid(videos: videos.sortedVideos(by: sortingState.favoriteVideoSorting).reversed(sortingState.favoriteVideoReversed),
							  showArtists: true, session: session, player: player)
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct FavoriteArtists: View {
	let session: Session
	let player: Player
	
	@EnvironmentObject var viewState: ViewState
	@EnvironmentObject var sortingState: SortingState
	
	var body: some View {
		List{
			VStack(alignment: .leading) {
				VStack {
					HStack {
						Text("Favorite Artists")
							.font(.largeTitle)
							.lineLimit(1)
						Spacer()
						LoadingSpinner()
						ZStack(alignment: .trailing) {
							Picker(selection: $sortingState.favoriteArtistSorting, label: Spacer(minLength: 0)) {
								Text("Added").tag(ArtistSorting.dateAdded)
								Text("Name").tag(ArtistSorting.name)
								Text("Popularity").tag(ArtistSorting.popularity)
							}
							.pickerStyle(SegmentedPickerStyle())
							.frame(width: PICKERWIDTH)
							.padding(.trailing, 32)

							ReverseButton(reversed: $sortingState.favoriteArtistReversed)
								.padding(.trailing, 4)
						}
					}
					if let artists = viewState.stack.last?.artists {
						HStack {
							Text("\(artists.count) \(artists.count == 1 ? "Artist" : "Artists")")
							Spacer()
						}
						ArtistGrid(artists: artists.sortedArtists(by: sortingState.favoriteArtistSorting).reversed(sortingState.favoriteArtistReversed), session: session, player: player)
					}
				}
				Spacer(minLength: 0)
			}
			.padding()
		}
	}
}

struct TrackItemView: View {
    let track: Track
    let session: Session
    let player: Player
    let isHovered: Bool
    let onHoverChange: (Bool) -> Void
    let onRemovedFromFavorites: () -> Void
    let onPressedPlay: () -> Void
    let showCover: Bool
    let isAlbumView: Bool
    @EnvironmentObject var viewState: ViewState
    @State private var isOffline: Bool = false
    @State private var isFavorite: Bool? = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if showCover {
                ZStack {
                    
                    if scenePhase == .active, let url = bestCoverURL(for: track, session: session, preferred: [160, 80]) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .empty:
                                Rectangle().fill(Color.secondary.opacity(0.2))
                            case .failure:
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                                    .foregroundColor(.secondary)
                            @unknown default:
                                Rectangle().fill(Color.secondary.opacity(0.2))
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 48, height: 48)
                    }

                    Rectangle()
                        .fill(Color.black.opacity(isHovered ? 0.35 : 0.0))
                        .frame(width: 48, height: 48)

                    if isHovered {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .imageScale(.medium)
                    }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(4)
                .onTapGesture {
                    onPressedPlay()
                }
                .onHover { hovering in
                    onHoverChange(hovering)
                }
                
            }
           

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                if(!isAlbumView){
                    if let artistName = track.artist?.name {
                        HStack(spacing: 6) {
                            Text(artistName)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(track.album.title)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                    } else {
                        Text(track.album.title)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                
            }.onTapGesture {
                onPressedPlay()
            }
            Spacer()
            if isFavorite ?? false {
                Button(role: .destructive) {
                    Task {
                        if await session.favorites?.removeTrack(trackId: track.id) == true {
                            await MainActor.run {
                                isFavorite = false
                                onRemovedFromFavorites()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "heart.slash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove from Favorites")
            } else {
                Button {
                    Task {
                        if await session.favorites?.addTrack(trackId: track.id) == true {
                            await MainActor.run {
                                isFavorite = true
                            }
                        }
                    }
                } label: {
                    Image(systemName: "heart")
                }
                .buttonStyle(.plain)
                .help("Add to Favorites")
            }
            Text(secondsToHoursMinutesSecondsString(seconds: track.duration))
            
            
        }
        .contentShape(Rectangle())
        .task(id: track.id) {
            // Refresh favorite state for this track
            isFavorite = await session.favorites?.doFavoritesContainTrack(trackId: track.id)
        }
        .contextMenu {
            Button {
                player.add(track: track, .now)
                player.play()
            } label: {
                Label("Play Now", systemImage: "play.fill")
            }

            Button {
                player.add(track: track, .next)
            } label: {
                Label("Play Next", systemImage: "text.insert")
            }

            Button {
                player.add(track: track, .last)
            } label: {
                Label("Play Last", systemImage: "text.append")
            }

            Divider()

            Button(role: .destructive) {
                Task {
                    await session.favorites?.removeTrack(trackId: track.id)
                    await MainActor.run {
                        onRemovedFromFavorites()
                    }
                }
            } label: {
                Label("Remove from Favorites", systemImage: "heart.slash")
            }
        }
    }
}

