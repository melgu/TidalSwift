# Stale View State

Several views copy offline or favorite state into `@State` once, in `.task` or `.onAppear`, and never update it. Found October 2026 by reading the code. Not reproduced in the app, and nothing fixed yet beyond the cases below.

## Background

Two things make a one-time copy go stale:

1. **Context menus are built from the view's first render.** On macOS, a `.contextMenu` doesn't rebuild when `@State` changes, so a value loaded in `.task` always arrives too late and the menu shows the default.
2. **Rows and grid items are kept when the view refreshes.** `viewState.refreshCurrentView()` reloads the data, but items with the same ID keep their identity, so `.task(id:)` doesn't run again.

Already fixed by reading the observable `OfflineDB` directly in a computed property: the offline state of albums and playlists in their context menus and grid items. Videos did it that way from the start.

## Open cases

### Offline state of tracks

`TrackList.swift` loads `isOffline` once via `offline.isTrackOffline(track:)`. For tracks, offline means the file is downloaded, which happens later in the sync. After a sync, `uiRefreshFunc` refreshes the current view, but existing rows keep their stale value. A freshly downloaded track probably shows no cloud until the view is recreated.

Fix: make the set of downloaded track IDs observable and read it in the row. `offlineTrackIds()` currently fills its cache lazily on read, which mustn't happen during a view update, so it would need to be loaded eagerly (at startup and after each sync) instead.

### Favorites

The same one-time pattern in about 10 places: `AlbumView`, `PlaylistView`, `ArtistView`, `TrackList` and every context menu (`isFavorite = await x.isInFavorites(session:)`).

- `Favorites` and its `FavoritesCache` in `TidalSwiftLib` aren't observable, so a change in one place (e.g. the context menu) doesn't update another (e.g. the heart in a track row).
- In the context menus, the value arrives after the menu is built. Albums, artists, playlists and tracks default to `false` and probably always offer "Add to Favorites". Videos default to `?? true` and probably always offer "Remove from Favorites".

Fix: make `Favorites` `@Observable` in the library (`Download` already uses Observation), give it a synchronous lookup against the cached IDs, and update the cache on add and remove. Views then read it in a computed property.

### Offline button in detail views

`AlbumView` and `PlaylistView` load `isOffline` once, but set it themselves when the cloud button is clicked. It only goes stale when the album or playlist is added or removed elsewhere while the view is open (Offline view, player bar menu).

Fix: the same computed property as the grid items.

## Not affected

- `EditPlaylistView` reads the offline state once when the sheet opens, which is correct for a sheet.
- `CreditsView`, `ArtistBioView` and `AccountInfoView` load their content once by design.
