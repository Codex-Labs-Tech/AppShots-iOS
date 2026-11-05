# Example and recipe validation

Checked 6 November 2026 on an Apple silicon Mac with Xcode 27.2 (27B52), Apple Swift 6.4.2,
and the iOS Simulator 27.2 SDK. Repository baseline: `5977f5f`.
All build outputs/logs are in ignored `.build/` under this checkout. No simulator was booted, installed or launched.
No Xcode test job or UI automation was run. No tags or package release were created.

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

## Unproved runtime limits

No claim is made that these screens rendered correctly, identifiers appeared in an accessibility tree, initial
navigation reached the detail, or the Mac capture/export flow completed. Those require a separate interactive run.
The included simulator slot may need adapting to an installed device/runtime. The example is English only and has
no persistent database, networking, authentication, Keychain or server state. It cannot prove integration with those
systems, asynchronous fixture loading, clock injection, snapshot portability, or production authorization boundaries.
