# iOS Search Field

The sidebar search field doesn't handle Esc or keyboard dismissal properly on iOS. Analysis from September 2026; nothing implemented yet.

## Current state

`SearchField` in `TidalSwift/Top-Level Views/TopDetailView.swift` is a plain `TextField` with a `@FocusState`. Three behaviors are built around that focus state:

- `onAppear` drops focus, because AppKit makes the first text field the window's first responder and Space should control playback right away.
- `.onExitCommand` drops focus on Esc, so Space controls playback again. `onExitCommand` is macOS/tvOS only, so it's guarded by `#if canImport(AppKit)`.
- `.focusedSceneValue(\.searchFieldFocus, $isFocused)` exposes the focus to the Find command (⌘F) in `TidalSwiftCommands` (`TidalSwift/TidalSwiftApp.swift`).

On iPad, pressing Esc on a hardware keyboard (e.g. Magic Keyboard) does nothing. It's also unverified whether the virtual keyboard dismisses as expected after submitting.

Deployment targets: macOS 14, iOS 17, visionOS 1.

## Option 1: `onKeyPress(.escape)` on iOS

Smallest change. `onKeyPress` is available from iOS 17, so it fits the `#else` branch:

```swift
#if canImport(AppKit)
.onExitCommand { isFocused = false }
#else
.onKeyPress(.escape) {
	isFocused = false
	return .handled
}
#endif
```

Open point: it's untested whether a focused `UITextField` on iPadOS passes Esc through to `onKeyPress`. The simulator can check this if its hardware keyboard is connected.

On macOS, `onExitCommand` stays. The field editor handles Esc as `cancelOperation`, which is what `onExitCommand` hooks into.

## Option 2: `.searchable` on iOS only

Use `.searchable` on iOS and keep the custom field on macOS.

Pros on iOS:

- Esc from a hardware keyboard, the Cancel button and keyboard dismissal all work natively.
- The field goes into the sidebar's navigation bar, which is the expected place on iPad. On iPhone it collapses along with the sidebar.

Things to handle:

- Submitting goes through `.onSubmit(of: .search)`, which then sets `viewState.searchTerm` / opens a pasted `TidalLink` and selects `.search`, like the current `onCommit`. `.searchable` is mainly meant for filtering the current view, but this works.
- ⌘F needs `.searchFocused(_:)`, which requires iOS 18. Below that, an `#available` fallback is needed and ⌘F won't focus the field.
- `NavigationView` is deprecated; `.searchable` behaves more predictably with `NavigationSplitView`. Migrating may be worth doing at the same time.

## Why not `.searchable` on macOS too

- On macOS it's backed by `NSSearchField`, where Esc clears the text but keeps focus. "Esc, then Space plays" would break, and `onExitCommand` can't be attached to the searchable field.
- ⌘F would need `.searchFocused(_:)`, which requires macOS 15, above the macOS 14 target.
- The field would move into the toolbar or sidebar search slot and look different. The `onAppear` trick that drops initial focus may not carry over.

## Virtual keyboard

Independent of the option chosen:

- A SwiftUI `TextField` on iOS is expected to close the keyboard on Return. Not verified yet.
- `.submitLabel(.search)` makes the Return key read "Search".
- `.scrollDismissesKeyboard(.interactively)` on the results lists lets scrolling dismiss the keyboard.

## Suggested order

Try Option 1 in the simulator first. If Esc doesn't reach `onKeyPress`, go with Option 2.
