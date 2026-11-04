# Trueframe for iOS

Formerly AppShots. The repository URL stays `https://github.com/Codex-Labs-Tech/AppShots-iOS`.
New integrations use the **Trueframe** product, `import Trueframe` and `Trueframe.start()`.
Existing **AppShots** product/import and `AppShots.start()` remain supported aliases of the same implementation;
capture/fixture/clock environment keys and the `Library/Application Support/AppShots/package.json` handshake stay unchanged
so existing Mac builds and app integrations continue to cooperate. No project data or app authentication is migrated.
The new product is available from this source revision after merge/release; the existing `0.1.0` tag is not rewritten.

The in-app half of [Trueframe](https://github.com/Codex-Labs-Tech), the Mac tool that captures App Store screenshots from the iOS Simulator. Optional: Trueframe works without it. Add it to get cleaner, steadier captures:

- **Capture mode.** `Trueframe.isCapturing` tells your app a screenshot is being taken, so it can skip what gets in the way: permission and biometric prompts, onboarding, review requests, tips, debug banners.
- **Fixtures.** Trueframe can ask your app to load a named set of demo data instead of the usual source.
- **Clock awareness.** `Trueframe.isClockSet` tells your app that Trueframe fixed its clock, so a guard against clock changes can stand down.

It does nothing unless Trueframe launches your app, and then only what your Trueframe project turns on. In release builds it compiles to empty stubs, so it can't activate in anything you ship.

## Install

1. In Xcode: **File › Add Package Dependencies…**, paste `https://github.com/Codex-Labs-Tech/AppShots-iOS`, and add the **Trueframe** library to your app target.
2. Start it early, in debug builds only. In a SwiftUI app:

   ```swift
   #if DEBUG
   import Trueframe
   #endif

   @main
   struct MyApp: App {
       init() {
           #if DEBUG
           Trueframe.start()
           #endif
       }
       // …
   }
   ```

   In a UIKit app, call it at the top of `application(_:didFinishLaunchingWithOptions:)`.
3. Run your app once from Trueframe. Its project window shows the package as detected.

## Use it

Skip interruptions while capturing:

```swift
#if DEBUG
if Trueframe.isCapturing { return }   // e.g. before asking for notification permission
#endif
```

Load demo data when Trueframe asks for it:

```swift
#if DEBUG
Trueframe.fixtures { set in
    store.load(fixtures: set)        // your own demo data, by name
}
#endif
```

## If your app guards its clock

Trueframe can set your app's clock to a fixed time of day (9:41, like the status bar), so "Good morning" and "Starts in 3 hours" read the same every run. It does this from outside, so it works without this package.

Some apps end the session when the clock moves, to stop people changing the time to get around a session limit or a token check. If yours does, Trueframe notices on the first capture (the app signs out), stops the run and turns its clock off for your project. To have both, skip your guard while Trueframe has set the clock:

```swift
func clockWasSetBack(since stored: Date, now: Date) -> Bool {
    #if DEBUG
    if Trueframe.isClockSet { return false }   // Trueframe moved it on purpose, for screenshots
    #endif
    return stored.timeIntervalSince(now) > 5 * 60
}
```

`isClockSet` is only ever true in a debug build that Trueframe launched with its clock on.

## How Trueframe talks to it

Trueframe passes launch settings as environment variables (`APPSHOTS_CAPTURE`, `APPSHOTS_CAPTURE_MODE`, `APPSHOTS_FIXTURES`, and `APPSHOTS_CLOCK_START` when it sets the clock). On start, the package writes `Library/Application Support/Trueframe/package.json` in your app's data folder with its version and what it was asked to do; that is how Trueframe detects it. Nothing leaves the simulator.

## Licence

MIT. See [LICENSE](LICENSE).
