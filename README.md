# AppShots for iOS

The in-app half of [AppShots](https://github.com/Codex-Labs-Tech), the Mac tool that captures App Store screenshots from the iOS Simulator. Optional: AppShots works without it. Add it to get cleaner, steadier captures:

- **Capture mode.** `AppShots.isCapturing` tells your app a screenshot is being taken, so it can skip what gets in the way: permission and biometric prompts, onboarding, review requests, tips, debug banners.
- **Fixtures.** AppShots can ask your app to load a named set of demo data instead of the usual source.
- **Clock awareness.** `AppShots.isClockSet` tells your app that AppShots fixed its clock, so a guard against clock changes can stand down.

It does nothing unless AppShots launches your app, and then only what your AppShots project turns on. In release builds it compiles to empty stubs, so it can't activate in anything you ship.

## Install

1. In Xcode: **File › Add Package Dependencies…**, paste `https://github.com/Codex-Labs-Tech/AppShots-iOS`, and add the **AppShots** library to your app target.
2. Start it early, in debug builds only. In a SwiftUI app:

   ```swift
   #if DEBUG
   import AppShots
   #endif

   @main
   struct MyApp: App {
       init() {
           #if DEBUG
           AppShots.start()
           #endif
       }
       // …
   }
   ```

   In a UIKit app, call it at the top of `application(_:didFinishLaunchingWithOptions:)`.
3. Run your app once from AppShots. Its project window shows the package as detected.

## Use it

Skip interruptions while capturing:

```swift
#if DEBUG
if AppShots.isCapturing { return }   // e.g. before asking for notification permission
#endif
```

Load demo data when AppShots asks for it:

```swift
#if DEBUG
AppShots.fixtures { set in
    store.load(fixtures: set)        // your own demo data, by name
}
#endif
```

## If your app guards its clock

AppShots can set your app's clock to a fixed time of day (9:41, like the status bar), so "Good morning" and "Starts in 3 hours" read the same every run. It does this from outside, so it works without this package.

Some apps end the session when the clock moves, to stop people changing the time to get around a session limit or a token check. If yours does, AppShots notices on the first capture (the app signs out), stops the run and turns its clock off for your project. To have both, skip your guard while AppShots has set the clock:

```swift
func clockWasSetBack(since stored: Date, now: Date) -> Bool {
    #if DEBUG
    if AppShots.isClockSet { return false }   // AppShots moved it on purpose, for screenshots
    #endif
    return stored.timeIntervalSince(now) > 5 * 60
}
```

`isClockSet` is only ever true in a debug build that AppShots launched with its clock on.

## How AppShots talks to it

AppShots passes launch settings as environment variables (`APPSHOTS_CAPTURE`, `APPSHOTS_CAPTURE_MODE`, `APPSHOTS_FIXTURES`, and `APPSHOTS_CLOCK_START` when it sets the clock). On start, the package writes `Library/Application Support/AppShots/package.json` in your app's data folder with its version and what it was asked to do; that is how AppShots detects it. Nothing leaves the simulator.

## Licence

MIT. See [LICENSE](LICENSE).
