# TrueFrame for iOS

The optional in-app companion to TrueFrame's Mac screenshot tool. Basic capture works **without this package**.
Add it when your app should deliberately load named local data or suppress optional UI during a capture.
It does not generate data, sign in, stub networking, set the clock, or navigate your app.

Formerly AppShots. The repository URL remains `https://github.com/Codex-Labs-Tech/AppShots-iOS`.
Use the **TrueFrame** product, `import TrueFrame`, and `TrueFrame.start()` for new integrations.
The **AppShots** product/import and `AppShots.start()` remain supported aliases sharing the same state.
`APPSHOTS_*` environment keys and the `Library/Application Support/AppShots/package.json` handshake are unchanged.
The TrueFrame product is available from this source revision; the existing `0.1.0` tag is not rewritten and
contains the older AppShots product. Package-reported version remains `0.1.0`.

## Start without the SDK

Use an app already installed on an iOS Simulator, or build a **simulator `.app`** in Xcode and give it to TrueFrame.
An App Store download, `.ipa`, or iPhone/device `.app` cannot run in the Simulator, even on an Apple silicon Mac.
Prepare a synthetic local/demo state manually, then use existing deep links or recorded taps to reach one screen.
Start with one device, one locale, one appearance; inspect the capture before expanding the matrix.
See [capture recipes](docs/capture-recipes.md) for the current Mac config and CLI handoff.

## Install and start early

1. In Xcode, choose **File › Add Package Dependencies…** and enter
   `https://github.com/Codex-Labs-Tech/AppShots-iOS`. Choose **Branch: main** (or pin a commit containing the
   TrueFrame product), then add **TrueFrame** to the app target. A version rule resolving to the existing `0.1.0`
   tag has only the older **AppShots** product/import. A checkout can also be added as a local package; the example does this.
2. Import and call it inside `#if DEBUG`. Create your store first, start the SDK, then call the fixture hook
   **before presenting views or starting normal loads**:

   ```swift
   import SwiftUI
   #if DEBUG
   import TrueFrame
   #endif

   @main
   struct MyApp: App {
       private let store: AppStore // your app's own store

       init() {
           let store = AppStore()
           #if DEBUG
           TrueFrame.start()
           TrueFrame.fixtures { name in
               store.loadFixture(named: name) // implement an explicit allowlist in your app
           }
           #endif
           self.store = store
       }

       var body: some Scene {
           WindowGroup { RootView(store: store) }
       }
   }
   ```

   This sketch uses app-owned types. [Trail Journal](Examples/TrailJournal/README.md) is the complete buildable version.
   For UIKit, use the same order in `application(_:didFinishLaunchingWithOptions:)`, before constructing the UI.
3. In the Mac capture set, request `"package": { "captureMode": true, "fixtures": "weekend-hikes" }`.
   The name must match app code. Rebuild the Debug simulator app after integration and use that build in TrueFrame.

`fixtures(_:)` invokes its closure immediately and synchronously if a nonempty name was requested.
It does not retain a registration, await a `Task`, or know whether the name exists. Calling it before `start()` misses
that launch's request. Fixture selection is independent of `isCapturing`; a project can request either feature alone.
For asynchronous app loading, [gate readiness explicitly](docs/capture-recipes.md#fixture-readiness).

## Choose capture behavior in app code

```swift
func offerOptionalTip() {
    #if DEBUG
    if TrueFrame.isCapturing { return }
    #endif
    // Present your ordinary local tip here.
}
```

Keep overrides and demo data inside `#if DEBUG` in your app too. The SDK's Release state is always inactive,
`fixtures` never invokes its closure, and `start()` writes nothing. Linking the package does not by itself remove
all library code from a Release binary. Do not define `DEBUG` in your shipping configuration.
In Debug, activation requires `APPSHOTS_CAPTURE=1`; anyone launching the app can supply that flag manually.
**Capture mode is not authorization.** Keep real account access, biometrics protecting real data, token validation,
and server permissions intact. Use isolated synthetic local data for demo screens.

## If your app guards its clock

The status bar's `9:41` changes only the status bar. App text based on `Date()` keeps following real time.
TrueFrame's Mac profile can separately opt into `appClock` injection, without this SDK; it is off by default.
`TrueFrame.isClockSet` only reports the Debug launch's `APPSHOTS_CLOCK_START` marker, not a clock set by this package.
It does not validate injection or guarantee that every time source is intercepted.

Clock shifts can expire tokens or trigger clock-change protections and sign users out. Leave `appClock` unset for
real sessions; do not copy a general clock/auth guard bypass. Prefer app-owned fixed display values in an isolated
Debug fixture when possible. Injection does not freeze server time or renew credentials.
Container snapshots omit Keychain and cannot freeze server state; [details and recovery](docs/capture-recipes.md#clock-authentication-and-snapshots).

## Launch protocol

| Debug environment | Meaning |
| --- | --- |
| `APPSHOTS_CAPTURE=1` | Enables reading capture settings and writing the detection file |
| `APPSHOTS_CAPTURE_MODE=1` | Sets `isCapturing` when the launch marker is present |
| `APPSHOTS_FIXTURES=<name>` | Sets `fixtureSet`; an empty string means no fixture |
| `APPSHOTS_CLOCK_START=<value>` | Presence sets `isClockSet` when the launch marker is present |

Call `start()` once per process launch. The detection file is
`Library/Application Support/AppShots/package.json` in the app's data container, **not** a `TrueFrame` directory.
It contains `version`, `features` (`captureMode`, `fixtures`, `clock`), `captureMode`, optional `fixtureSet`,
`clockSet`, and ISO-8601 `startedAt`. These are supported capabilities and requested settings, not proof that
app-owned fixture loading or optional clock injection succeeded. The Mac tool clears/reads this file for detection.
The SDK itself makes no network requests.

## Example and checks

[Trail Journal](Examples/TrailJournal/README.md) includes a normal Xcode project, local package dependency,
named synthetic fixtures, validated debug launch links and content accessibility identifiers. No service or account is needed.

From this repository root, with Xcode's command-line tools selected:

```sh
swift test --scratch-path .build/host -j 4
swift build --scratch-path .build/host -c release -j 4
swift test --scratch-path .build/host -c release -j 4
```

These run on the host and do not launch a simulator. See the example README for Debug/Release simulator build commands
and [validation evidence](docs/validation.md) for what was checked and what remains unproved.

## Licence

MIT. See [LICENSE](LICENSE).
