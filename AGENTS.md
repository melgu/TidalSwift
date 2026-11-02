# Repository Guidelines

## About This Project

TidalSwift is a macOS Tidal Music Streaming Client written in Swift. It supports streaming, offline playback, downloads, lyrics, new releases from favorite artists, and playlist management — all via the unofficial Tidal API.

## Project Structure & Module Organization

`TidalSwift` contains the macOS app target (views, UI helpers, assets, and app lifecycle code).
The API/client library (session endpoints, codable models, downloads, metadata, and networking) lives in its own repo, [TidalSwiftLib](https://github.com/melgu/TidalSwiftLib), checked out next to this one at `../TidalSwiftLib`. The `tidal` command line tool and its MCP server live in [TidalSwiftCLI](https://github.com/melgu/TidalSwiftCLI), which depends on the library as well. Each repo has its own guidelines; read the library's `AGENTS.md` before changing it.
`TidalSwift.xcodeproj` defines the shared `TidalSwift` scheme. It references TidalSwiftLib as a local Swift package at `../TidalSwiftLib`, whose scheme Xcode generates.
`README.assets` stores images used in project documentation, not runtime app assets.
`docs` holds developer notes: API research, investigations, and plans for larger changes. Check it for background before working on a related area, and add findings there that are worth keeping but don't belong in code comments.

Keep app-facing code in `TidalSwift/...` and platform-agnostic API/domain logic in TidalSwiftLib. A change that spans both needs a commit in each repo.

## Architecture

### Key Subsystems

**Networking (TidalSwiftLib):** All Tidal API calls go through the library's `Session`, which holds auth state and stores the login in the login keychain under the `keychainService` passed to it. The app uses its bundle identifier.

**State Management (`TidalSwift/Helpers/`):**
- `ViewState.swift` — navigation stack, view history, and per-view cached content
- `PlaybackInfo.swift` — observable playback metadata (current track, position)
- `QueueInfo.swift` — observable queue state
- `SortingState.swift` — observable sort preferences

All state objects are `@Observable` classes, injected with `.environment(_:)` and read via `@Environment(Type.self)` (or passed directly, with `@Bindable` where a view needs bindings). Persisted properties set an `@ObservationIgnored` `hasUnsavedChanges` flag in `didSet`. `TidalSwiftAppModel` in `TidalSwiftApp.swift` owns all instances and saves flagged state to UserDefaults via JSON encoding from a 10-second task loop and on app quit. The project doesn't use Combine.

**Player (`TidalSwift/Player.swift`):** Thin `AVPlayer` wrapper that manages the playback queue, shuffle, repeat, and stream URL resolution.

**Offline (`TidalSwift/Offline.swift`):** Keeps favorite tracks, albums, playlists and videos in the Music folder for offline playback and syncs them. It's app-only, owned by `TidalSwiftAppModel` and read via `@Environment(Offline.self)`, so a library user can't start a sync that deletes the offline files.

**Downloads (TidalSwiftLib):** The library downloads and tags tracks, albums, artists, playlists and videos into the destination given by `DownloadOptions`, which also sets audio quality and Dolby Atmos. The app passes its offline settings and the Downloads folder.

### Swift Package Manager Dependencies

- `TidalSwiftLib` — the Tidal API, models and downloads
- `UpdateNotification` — in-app update checking

## Build, Test, and Development Commands

Use Xcode's MCP if possible.

- `open TidalSwift.xcodeproj`
  Open the project in Xcode.
- `xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwift -configuration Debug build`
  Build the macOS app from CLI.
- `xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwiftLib -configuration Debug build`
  Build the library.

There is no automated test suite. If `xcodebuild` fails due to local simulator/cache issues, build directly in Xcode and capture the exact error in the PR.

## Coding Style & Naming Conventions

Indent with tabs, one per level, never spaces. Xcode and many tools default to four spaces, so check new code. `.editorconfig` encodes this for editors that support it.
Types use `UpperCamelCase`; functions/properties use `lowerCamelCase`; file names match the primary type/feature (`ArtistView.swift`, `SearchResults.swift`).
Prefer `async/await` over callback-style APIs for new async work (the codebase was recently migrated from callbacks).
Never mess with indentation or whitespace on unrelated lines, but make sure that new or edited blocks have correct indentation.
Blank lines inside a type or function carry the indentation of the surrounding block (e.g. a single tab between two methods), they are not left empty. Only blank lines at the top level of a file are empty. Editors and tools tend to strip this whitespace, so check the diff of new or edited code for bare blank lines (`git diff | grep -n '^+$'`).
Default Actor Isolation is set to `MainActor` and Approachable Concurrency is enabled.
Log with OSLog instead of `print`: declare `private let logger = Logger(category: "<FileName>")` per file, using the `Logger(category:)` init in `TidalSwift/Helpers/Logger.swift` (subsystem `de.melgu.TidalSwift`). Log tokens, credentials and request headers only with `privacy: .private`, never `.public`.

## Commit & Pull Request Guidelines

Match the existing commit style: short, imperative, and specific (`Fix login`, `Update Xcode project`, `Bump build number`).
Keep commits scoped to one logical change.
PRs should include:
- concise summary of user-visible/technical changes
- linked issue (if available)
- manual test notes
- screenshots or recordings for UI changes

## Security & Configuration Tips

Do not add personal tokens, account data, or local secrets to commits.
Auth and API changes belong in TidalSwiftLib, whose `Config.swift` holds sensitive integration settings.
