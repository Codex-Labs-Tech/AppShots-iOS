# AppShots for iOS

The in-app half of [AppShots](https://github.com/Codex-Labs-Tech), the Mac tool that captures App Store screenshots from the iOS Simulator. Optional: AppShots works without it. Add it to get cleaner, steadier captures:

- **Capture mode.** `AppShots.isCapturing` tells your app a screenshot is being taken, so it can skip what gets in the way: permission and biometric prompts, onboarding, review requests, tips, debug banners.
- **Fixtures.** AppShots can ask your app to load a named set of demo data instead of the usual source.

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

## How AppShots talks to it

AppShots passes launch settings as environment variables (`APPSHOTS_CAPTURE`, `APPSHOTS_CAPTURE_MODE`, `APPSHOTS_FIXTURES`). On start, the package writes `Library/Application Support/AppShots/package.json` in your app's data folder with its version and what it was asked to do; that is how AppShots detects it. Nothing leaves the simulator.

## Licence

MIT. See [LICENSE](LICENSE).
