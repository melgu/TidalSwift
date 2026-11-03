<img src="README.assets/Icon.png" alt="Icon" width="128">

# TidalSwift

Tidal Music Streaming Client for macOS, written in Swift

It supports all major features of the official Tidal app, while adding additional ones, like New Releases, Lyrics, automatic Dark Mode, Downloads & Offline Playback – all while being only 1/10th the size of the official app.

The app is built on [TidalSwiftLib](https://github.com/melgu/TidalSwiftLib), my Swift library for the Tidal API.

> [!IMPORTANT]
>
> **New: TidalSwift for the terminal and for AI assistants** 🎉
>
> [TidalSwiftCLI](https://github.com/melgu/TidalSwiftCLI) brings the `tidal` command line tool: search, new releases of your favorite artists, playlists, favorites and downloads, right from the terminal. It also runs as an MCP server, so AI assistants can search your library, edit playlists or answer questions like "What's the latest album of my favorite artist?".



## Download

The easiest way is [Homebrew](https://brew.sh), which also takes care of the steps below:

```sh
brew install --cask melgu/tap/tidalswift
```

Or download the latest version [here](https://github.com/melgu/TidalSwift/releases).
After downloading and unpacking the TidalSwift.zip, move the app to the Applications folder. Because the app is unsigned (I refuse to give current Apple money), you need to explicitly allow the app after the first start in the Privacy system settings. Alternatively, you can execute this:

```sh
xattr -d com.apple.quarantine /Applications/TidalSwift.app
```



## Impressions

### New Releases

Unlike the official Tidal app, TidalSwift can display new releases by your favorite artists.

![New Releases](README.assets/NewReleases.png)

### Lyrics

Also, unlike the official app, it can display the Lyrics of the currently playing song.

<img src="README.assets/Lyrics.png" alt="Lyrics" width="400">

### Offline

This is a big one. The official desktop app still doesn't support offline playback – and probably never will. This app does!

![My Mixes](README.assets/OfflineTracks.png)

### Downloads

It even goes a step further. You can download music to your hard drive and do with it whatever you want.

<img src="README.assets/Downloads.png" alt="Context Menu: Download highlighted" width="180">

### My Mixes

![My Mixes](README.assets/MyMixes.png)

### Search

![Search](README.assets/Search.png)

### Favorites

![Playlists](README.assets/Playlists.png)

![Albums](README.assets/Albums.png)

![Tracks](README.assets/Tracks.png)

![Videos](README.assets/Videos.png)

![Artists](README.assets/Artists.png)

### Detail Views

![Album View](README.assets/AlbumView.png)

![Artist View](README.assets/ArtistView.png)

### Login

![Login](README.assets/Login.png)

### Credits

<img src="README.assets/Credits.png" alt="Credits" width="400">

### Dark Mode

TidalSwift obviously supports the macOS Dark Mode.

![Artist View (Dark Mode)](README.assets/ArtistView-DarkMode.png)



## License

TidalSwift is licensed under the [GNU General Public License v3.0](LICENSE).
