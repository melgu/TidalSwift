# Combine → async/await + Observation migration plan

State at time of writing: `main` at `87b124e`; line numbers updated to `ac9ec4f`. All `DispatchWorkItem` and all but one
`DispatchQueue` usage are gone; what remains is Combine.

Both targets set MainActor as the default actor isolation
(`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in the app target,
`.defaultIsolation(MainActor.self)` in `TidalSwiftLib/Package.swift`), and the
deployment target is macOS 14 (`MACOSX_DEPLOYMENT_TARGET = 14`, package
`platforms: [.macOS(.v13), .iOS(.v16)]`).

## Remaining Combine, by kind

| Site | Kind | Replacement |
| --- | --- | --- |
| `TidalSwift/TidalSwiftApp.swift:418` | `objectWillChange` forwarding | delete |
| `TidalSwift/TidalSwiftApp.swift:423`–`:465` | 23 dirty-flag sinks | `didSet` in the state objects |
| `TidalSwift/TidalSwiftApp.swift:467` | `Timer.publish` | `Task` + `Task.sleep` |
| `TidalSwift/Player.swift:48-49` | side-effecting sinks | move the effect to the write |
| `TidalSwift/Pop-Ups/LoginView.swift:119` | subject consumption | `AsyncStream` + `.task` |
| `TidalSwiftLib/.../Session/Login.swift:70` | `CurrentValueSubject` API | `AsyncStream` |
| everywhere | `.receive(on: DispatchQueue.main)` | delete |

## 1. `uiRefreshCancellable` — pure deletion

```swift
uiRefreshCancellable = Publishers.Merge(player.playbackInfo.objectWillChange, player.queueInfo.objectWillChange)
    .sink { [weak self] _ in self?.objectWillChange.send() }
```

This exists only so views watching the app model re-render when nested state
changes. `@Observable` tracks nested objects per-property, so the forwarding has
no replacement — it goes away.

## 2. The 23 dirty-flag sinks — `didSet` inside the state objects

Every one of them does the same thing:

```swift
volumeCancellable = player.playbackInfo.$volume.receive(on: DispatchQueue.main).sink { [weak self] _ in
    self?.savePlaybackInfoOnNextTick = true
}
```

`@Observable` has no `$property`, but `didSet` coexists with the macro, and the
property *stays observable*. Verified at `-target arm64-apple-macos14`, with
observation firing first (willSet ordering) and the observer after:

```
observation fired for withObserver
didSet fired
```

So the flag moves next to the data it describes:

```swift
@Observable final class SortingState {
    var favoriteAlbumSorting: AlbumSorting = .dateAdded { didSet { hasUnsavedChanges = true } }
    // …
    @ObservationIgnored var hasUnsavedChanges = false
}
```

`@ObservationIgnored` keeps the flag itself from triggering redraws. The save
loop reads `sortingState.hasUnsavedChanges` instead of the app model's
`saveSortingStateOnNextTick`.

This deletes the 23 sinks, the 23 `AnyCancellable` properties
(`TidalSwiftApp.swift:77`–`:102`), and all of `cancelCancellables()` (`:486`).

Alternative, if per-property `didSet` is not wanted: one re-arming
`withObservationTracking` loop per state object (3 total), whose `apply` closure
reads every persisted property. Works on macOS 14. Two caveats: it fires on
willSet, so it is only good for a dirty flag, not for reading the new value; and
it must be re-armed after each change. The `for await` form that would make this
a three-liner, `Observations`, is `@available(anyAppleOS 26.0, *)` — unusable at
deployment target 14 without gating.

## 3. `Timer.publish` — a task loop

```swift
saveTask = Task {
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(10))
        saveDirtyState()
    }
}
```

Cancelled from `prepareForTermination()`, where `cancelCancellables()` is today.

## 4. Player's two sinks — the only Combine doing real work

```swift
volumeCancellable = playbackInfo.$volume.receive(on: DispatchQueue.main).sink(receiveValue: setVolume(to:))
shuffleCancellable = playbackInfo.$shuffle.receive(on: DispatchQueue.main).sink(receiveValue: shuffle(enabled:))
```

These react to UI writes, so don't observe — put the effect where the write
lands. Either `didSet` on `PlaybackInfo.volume` calling into the player, or
better, move both properties onto `Player`, so the slider binds to
`player.volume` and its setter talks to `AVPlayer` directly. Side-effecting
state belongs on the object that performs the effect; `PlaybackInfo` goes back
to being plain data. Removes `@preconcurrency import Combine` from
`Player.swift` and the `deinit` cancellation.

## 5. Login — needs a library change

`Session.startAuthorization()` (`TidalSwiftLib/Sources/TidalSwiftLib/Session/Login.swift:70`)
returns `CurrentValueSubject<AuthorizationState, Never>`, but the polling behind
it (`:95`–`:144`) is already async/await and only publishes into the subject.
Return an `AsyncStream<AuthorizationState>` instead, yielding at the points that
currently call `subject.send(_:)`, and the view becomes:

```swift
.task {
    for await state in session.startAuthorization() {
        switch state { /* … */ }
    }
}
```

That removes the `cancellables` set, the `assign(to:on:)`, the `.receive(on:)`,
and `import Combine` from both `LoginView.swift` and the library.

## 6. `.receive(on: DispatchQueue.main)` — delete

With MainActor as default isolation in both targets, these hops are the same
redundancy already removed in `fe575d6` and `24734af`.

## Injection mechanics for the Observation move

- `@Published var x` → `var x`
- `ObservableObject` → `@Observable`
- `@StateObject` → `@State`
- `@EnvironmentObject var viewState: ViewState` → `@Environment(ViewState.self) var viewState`
- `.environmentObject(x)` → `.environment(x)`
- `@ObservedObject` → plain `let`, or `@Bindable` where the view needs bindings

`@EnvironmentObject` and `@Environment` cannot be mixed for the same object, so
each object's conversion has to land across all of its views at once.

Objects to convert: `ViewState`, `PlaybackInfo`, `QueueInfo`, `SortingState`,
`LoginInfo`, `PlaylistEditingValues`, `TidalSwiftAppModel`, and `DownloadStatus`
in the library.

## Suggested order

Each step is independently shippable and leaves the app building.

1. **Auth stream** — `Login.swift` + `LoginView.swift`. Self-contained; removes Combine from the library except `DownloadStatus`.
2. **Player ownership of volume/shuffle** — removes Combine from `Player.swift`.
3. **`SortingState` → `@Observable`** with `didSet` flags. Leaf object, few call sites; establishes the pattern.
4. **`PlaybackInfo` / `QueueInfo` → `@Observable`**, delete the `objectWillChange` forwarder.
5. **`ViewState` → `@Observable`** (widest: ~20 views move to `@Environment`), then the app model, then timer → task and the last `import Combine` removals.

Step 5 is the only one with real breadth. Everything before it touches one file
or one object.
