<img src="README.assets/Icon.png" alt="Icon" width="128">

# TidalSwift

Tidal Music Streaming Client & Library written in Swift

It supports all major features of the official Tidal app, while adding additional ones, like New Releases, Lyrics, Dark Mode, Downloads & Offline Playback – all while being only 1/10th the size of the official app.



## <span style="color:#B00000"> Recent changes </span>

Due to a very recent change in the Tidal API, the login mechanism has changed. Before, you were asked for your username and password. Now, you need to provide an authorization key, which you can get by logging in a desktop web browser and than looking at the XHR queries in the developer view. From there, note the `authorization` header. Also look for the `countryCode` parameter in the query itself. Now visit your favorite tracks and look for the related query in the delevoper view. It will look something like this: `/v1/users/12345678/favorites/tracks`. The number in there is your user id. Use those three values to log into TidalSwift.

I am working on bringing back the easy login from before.

Also note, that Offline storage doesn't work correctly at this point. Files are not getting deleted as they should. Downloads are not affected.



## Download

You can download the latest version [here](https://github.com/melgu/TidalSwift/releases).
After downloading and unpacking the TidalSwift.zip, move the app to the Applications folder. If you get a GateKeeper warning on first launch, right-click the app, select open and confirm your action in the dialog popping up. Sometimes this needs to be done twice. Alternatively you can allow the app in System Settings -> Security.




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

