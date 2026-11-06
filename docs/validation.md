# Example and recipe validation

Checked 6 November 2026 on an Apple silicon Mac with Xcode 27.2 (27B52), Apple Swift 6.4.2,
and the iOS Simulator 27.2 SDK. Repository baseline: `5977f5f`.
The initial compiler/host checks below kept their outputs/logs in ignored `.build/` under that checkout. Those checks
did not boot, install or launch a simulator, or run Xcode UI tests. A subsequent runtime capture rehearsal is recorded
separately below. Neither phase created tags or a package release.

## Host checks

Exact commands, run from the repository root:

```sh
swift test --scratch-path .build/host -j 4
swift build --scratch-path .build/host -c release -j 4
swift test --scratch-path .build/host -c release -j 4
```

- Debug: **10 tests passed**, 0 failures (6 SDK, 4 example logic).
  Covers AppShots alias/shared state, the legacy detection directory and version/features,
  launch gating, synchronous non-retained fixture hooks, fixture requests independent of capture mode,
  empty fixture handling, clock-marker reporting, named/unknown fixture data, strict destination/argument
  validation, and ordinary inactive example startup.
- Release build: passed. Release: **2 tests passed**, 0 failures.
  Every capture environment key is supplied: SDK state stays inactive, no fixture callback runs and no handshake
  is written. The actual example adapter also stays empty, keeps its local tip, and ignores a debug launch link.
- Final host runs emitted no compiler warnings.

## Simulator compile checks

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

Both reported **BUILD SUCCEEDED**, compiling arm64 and x86_64 simulator variants with the checkout's local TrueFrame
product. No third-party dependency was fetched. Xcode emitted its standard “Metadata extraction skipped, no
AppIntents.framework dependency found” warning; the app does not use App Intents.

Outputs are `.build/example/Build/Products/Debug-iphonesimulator/TrailJournal.app` and the corresponding
`Release-iphonesimulator/TrailJournal.app`. A byte scan of the app executable and top-level dylibs found
`weekend-hikes`, `Cedar Loop` and `-trueframe-link` in `TrailJournal.debug.dylib`, and none in the Release binaries.
This supports the compile-time fixture/link boundary; it is not proof of app runtime behavior. Scan command:

```sh
python3 - <<'PYSCAN'
from pathlib import Path
for configuration in ['Debug', 'Release']:
    app = Path(f'.build/example/Build/Products/{configuration}-iphonesimulator/TrailJournal.app')
    binaries = [p for p in app.iterdir() if p.name == 'TrailJournal' or p.suffix == '.dylib']
    for marker in [b'weekend-hikes', b'Cedar Loop', b'-trueframe-link']:
        matches = [p.name for p in binaries if marker in p.read_bytes()]
        print(configuration, marker.decode(), ', '.join(matches) if matches else 'absent')
PYSCAN
```

## Config and self-review

With a separately available current Mac CLI on PATH:

```sh
trueframe validate -p Examples/TrailJournal/Capture
```

Result: `app-store: 2 captures`, `OK`, exit 0. This is structural validation, with no device interaction.
The schema, package environment mapping and handshake reader were also checked against current Mac source
(revision `6a6ad85`, read only). That source checkout is not needed to build this public example.

```sh
plutil -lint Examples/TrailJournal/TrailJournal.xcodeproj/project.pbxproj
git diff --check
```

Both passed. Self-review checked startup order, Debug conditions in app/package, explicit unknown fixture handling,
exact link validation, literal content identifiers, local-only fixture sources, relative package/config paths,
and unchanged public APIs, compatibility product, environment keys, version and detection format/location.
SDK implementation changes are documentation comments only.

## Runtime capture and controlled second build

A subsequent **6 November 2026** local rehearsal used SDK/example source
`261db07d8e44f0d6d7793087da9028dc47e40616`, macOS 27.0.1, Xcode 27.2 and an iPhone 17 Pro simulator on iOS 27.0.
The supplied capture project was copied and adapted to the actual device, 1206 × 2622 size and an isolated app bundle ID.
Both Debug simulator builds had signing disabled. No SDK implementation/API/protocol change was needed.

Observed through the app UI, actual screenshots, saved accessibility trees and capture manifests:

- A normal launch showed the empty journal and local tip. It did not load demo data.
- TrueFrame requested capture mode and `weekend-hikes`; both journal and initial detail-link flows captured successfully.
  The three synthetic trails and Cedar Loop note rendered. Their waits found `journal.trail.cedar-loop` and
  `trail.note.cedar-loop` in real accessibility trees. Neither captured tree contained `journal.tip` or `journal.empty`.
  Both records reported SDK 0.1.0, capture mode true and the requested fixture.
- Both plain PNGs exported successfully from the Mac viewer in fastlane layout, with size/alpha/preflight checks passing.
- A controlled build 2 changed the detail note and its identifier to `trail.notes.cedar-loop`. Reopening the same capture
  project marked both old captures Out of Date, naming builds 1 and 2. Run Out of Date refreshed the journal and failed
  the detail's old identifier wait. The inspector showed the closest new identifier and the stopped screen.
- Editing the flow and running Test recaptured only the failed detail. The journal's capture record/time was unchanged
  by that repair. The existing exported PNGs and marker stayed byte-identical through installation, failure and repair.
- Final export contained both RGB PNGs, 1206 × 2622 with no alpha. Journal was byte-identical to its baseline; only the
  intentionally changed detail differed.

This closes the earlier gap for the example's Debug fixture/link/identifier capture path. It is a controlled,
same-session internal rehearsal, not a customer's later release, a time-savings benchmark or general-app validation.
Runtime evidence/builds were retained locally; no screenshots or app binaries were added to this repository,
and no package release tags were created.

## Remaining limits

The supplied simulator slot still needs adapting to the installed device/runtime. This example is English only and has
no persistent database, networking, authentication, Keychain or server state. The rehearsal does not prove integration
with those systems, asynchronous fixture loading, clock injection, snapshot portability, minimum-OS behavior or production
authorization boundaries. Release inactivity remains covered by the compiler/host checks above; Release was not launched
in this runtime rehearsal. Capture/preflight success does not replace human visual review or certify arbitrary app data.
