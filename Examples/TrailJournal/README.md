# Trail Journal

A small SwiftUI iOS 16+ app using the TrueFrame package from this checkout via `../..`.
No private repository, remote package, service, account, image download or signing identity is required for simulator builds.
The UI is English only; this example does not demonstrate translated app content.

## Build

Open `TrailJournal.xcodeproj` in Xcode and choose the shared **TrailJournal** scheme and a simulator destination.
Or run these commands **from the repository root** (no simulator is booted or launched):

```sh
xcodebuild -project Examples/TrailJournal/TrailJournal.xcodeproj \
  -scheme TrailJournal -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/example \
  -clonedSourcePackagesDirPath .build/example-packages -jobs 4 CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Examples/TrailJournal/TrailJournal.xcodeproj \
  -scheme TrailJournal -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/example \
  -clonedSourcePackagesDirPath .build/example-packages -jobs 4 CODE_SIGNING_ALLOWED=NO build
```

Outputs: `.build/example/Build/Products/{Debug,Release}-iphonesimulator/TrailJournal.app`.
These are compile checks, not runtime or screenshot proof. Host checks for the actual example model and adapter run
with the root `swift test` commands in the [SDK README](../../README.md#example-and-checks).

## What to copy

- [TrailJournalApp.swift](App/TrailJournalApp.swift) constructs an empty local journal before making the first view.
- [CaptureSetup.swift](App/CaptureSetup.swift) starts TrueFrame, immediately consumes the fixture request, and only then
  resolves a launch link. Capture mode hides a local tip. No security checks are bypassed.
- [Journal.swift](App/Journal.swift) owns the `weekend-hikes` fixture: three invented walks with plausible distances,
  durations and notes. No people, emails, credentials, real locations, current dates or remote images are required.
  Loading it is repeatable; unknown names preserve data and show a debug diagnostic through the adapter.
- [ContentView.swift](App/ContentView.swift) uses literal accessibility identifiers and stable record IDs:
  `journal.trail.cedar-loop`, `journal.trail.willow-lake`, `journal.trail.meadow-path`, and `trail.note.cedar-loop`.
  They do not derive from visible titles or localized strings. The normal empty state has `journal.empty`;
  the optional tip has `journal.tip`; an unsupported fixture has `journal.fixture-error`.

An ordinary Debug launch shows the empty journal and tip. Release always uses that ordinary path, even if capture
flags and debug link arguments are supplied: fixture definitions, SDK calls and the link parser are under `#if DEBUG`.
The app has no persistence, so each launch starts fresh.

## Debug capture inputs

For a manual Debug run from Xcode, add these scheme environment values:

```text
APPSHOTS_CAPTURE=1
APPSHOTS_CAPTURE_MODE=1
APPSHOTS_FIXTURES=weekend-hikes
```

Optionally add launch arguments `-trueframe-link trailjournal://journal` or
`-trueframe-link trailjournal://trail/cedar-loop`. The parser accepts only the documented journal shape or a detail
for a loaded record; unknown destinations, extra paths, query strings, fragments, credentials and ports are rejected.
Repeated/missing argument values are ignored. Links are a debug **launch argument** feature, not registered OS URL handlers
or universal links. No `openURL` flow is required. In an existing app, keep normal deep links subject to its real access rules.

## Mac capture handoff

[Capture/project.json](Capture/project.json) uses the current schema. After building Debug, stage the simulator app:

```sh
mkdir -p Examples/TrailJournal/Capture/Builds
ditto .build/example/Build/Products/Debug-iphonesimulator/TrailJournal.app \
  Examples/TrailJournal/Capture/Builds/TrailJournal.app
```

Edit `devices.phone` for an available simulator name/runtime and its actual pixel dimensions.
The included device is an example slot, not a promise that the device/runtime is installed.
Open the capture folder in TrueFrame and use its setup check to install the staged build where needed.
If using the CLI, have the simulator app installed first; `run` does not build this Xcode project.
With a separately available `trueframe` CLI on PATH:

```sh
trueframe validate -p Examples/TrailJournal/Capture
trueframe check -p Examples/TrailJournal/Capture
trueframe run -p Examples/TrailJournal/Capture --set app-store
```

`validate` is structural only. `check` inspects local setup; `run` drives a simulator and is an optional runtime step.
The two flows wait for loaded content IDs, then the tool applies settle detection. App-clock injection is left off;
fixtures use fixed display values. Review the actual screenshots before trusting navigation, identifiers or layout.
Builds and captures are ignored by Git. See the [integration recipes](../../docs/capture-recipes.md) for boundaries.
