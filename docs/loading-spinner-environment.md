# Loading Spinner Environment

`LoadingSpinner` always requires `ViewState` in the environment, even when its caller supplies its own loading state. Any window that shows a spinner without injecting `ViewState` crashes. Noted October 2026; nothing changed yet.

## Current state

`LoadingSpinner` and its wrapper `FullscreenLoadingSpinner` are in `TidalSwift/Partial Views/LoadingSpinner.swift`. The spinner declares `@Environment(ViewState.self)` and uses it for two things:

- **Fallback state.** Without an `externalState`, it shows the loading state of the main window's current view (`viewState.stack.last?.loadingState`). Most callers rely on this.
- **Retry button.** In the `.error` state it shows a button that calls `viewState.refreshCurrentView()`, which reloads the main window's current view.

Callers that pass their own state still need `ViewState`, because SwiftUI resolves `@Environment` unconditionally. A missing value hits an assertion in `EnvironmentValues.subscript.getter` and terminates the app.

Secondary windows are created with `ResizableWindowControllerFactory` and don't inherit the main window's environment. Each one has to inject what its view tree needs, including views nested deep inside it. `AccountInfoView` shows `FullscreenLoadingSpinner(.loading)` and crashed on open until its window got `.environment(viewState)`.

A second, smaller issue: in a secondary window, the retry button reloads the main window's view, not the content of the window it's in.

## Possible fix

Split the spinner by where its state comes from:

- A plain spinner that takes its state (and optionally a retry action) as parameters and reads nothing from the environment. Secondary windows and callers with their own state use this one.
- A main-window spinner that reads `ViewState` for the fallback state and the retry action, and wraps the plain one.

Alternatively, secondary windows could use a plain `ProgressView` instead.

Either way, views outside the main window would no longer need `ViewState` just to show a spinner.
