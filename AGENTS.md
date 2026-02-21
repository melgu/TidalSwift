# Repository Guidelines

## About This Project

TidalSwift is a macOS Tidal Music Streaming Client written in Swift. It supports streaming, offline playback, downloads, lyrics, new releases from favorite artists, and playlist management — all via the unofficial Tidal API.

## Project Structure & Module Organization

`TidalSwift` contains the macOS app target (views, UI helpers, assets, and app lifecycle code).
`TidalSwiftLib` contains the reusable API/client library (session endpoints, codable models, downloads, metadata, and networking).
`TidalSwift.xcodeproj` defines shared schemes for both targets.
`README.assets` stores images used in project documentation, not runtime app assets.

Keep app-facing code in `TidalSwift/...` and platform-agnostic API/domain logic in `TidalSwiftLib/...`.

## Architecture

### Key Subsystems

**Networking (`TidalSwiftLib/Network.swift`):** Async/await HTTP client supporting GET/POST/DELETE. All Tidal API calls go through `Session` (`TidalSwiftLib/Session/Session.swift`), which holds auth state and constructs requests. API credentials live in `TidalSwiftLib/Config.swift` — treat these as sensitive.

**State Management (`TidalSwift/Helpers/`):**
- `ViewState.swift` — navigation stack, view history, and per-view cached content
- `PlaybackInfo.swift` — observable playback metadata (current track, position)
- `QueueInfo.swift` — observable queue state
- `SortingState.swift` — observable sort preferences

All state objects use `@Published` and are injected as `@EnvironmentObject` into SwiftUI views. `AppDelegate.swift` owns all instances, wires up Combine subscriptions (`AnyCancellable`), and persists state to UserDefaults via JSON encoding on a timer and on app quit.

**Player (`TidalSwift/Player.swift`):** Thin `AVPlayer` wrapper that manages the playback queue, shuffle, repeat, and stream URL resolution.

**Offline & Downloads (`TidalSwiftLib/`):** The `Offline` and `Download` modules handle caching tracks locally and syncing favorites for offline use.

**Models (`TidalSwiftLib/Codables/`):** `Codable` structs for every Tidal entity — `Album`, `Artist`, `Track`, `Video`, `Playlist`, login responses, etc.

### Swift Package Manager Dependencies

- `UpdateNotification` — in-app update checking
- `swiftui-sliders` — custom slider UI component
- `SwiftTagger` — audio file metadata tagging for downloads

## Build, Test, and Development Commands

- `open TidalSwift.xcodeproj`
  Open the project in Xcode.
- `xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwift -configuration Debug build`
  Build the macOS app from CLI.
- `xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwiftLib -configuration Debug build`
  Build the framework target.

There is no automated test suite. If `xcodebuild` fails due to local simulator/cache issues, build directly in Xcode and capture the exact error in the PR.

## Coding Style & Naming Conventions

Use Swift defaults with tabs/indentation matching existing files.
Types use `UpperCamelCase`; functions/properties use `lowerCamelCase`; file names match the primary type/feature (`ArtistView.swift`, `SearchResults.swift`).
Prefer `async/await` over callback-style APIs for new async work (the codebase was recently migrated from callbacks).
Indentation using tabs.

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
Treat auth/config constants in `TidalSwiftLib/Config.swift` as sensitive integration settings; discuss API/auth changes in the PR description.
