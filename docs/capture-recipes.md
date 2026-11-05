# Capture recipes

The SDK is optional. These recipes describe the current iOS API and Mac schema, not proposed network stubbing,
automatic fixture generation, translation or an MCP service. The public SDK does not install a Mac CLI.
Use a separately available TrueFrame Mac app/CLI; no private source checkout is a prerequisite for this example.

## Existing app: the smallest path

1. Build for **iOS Simulator** using Xcode, or obtain a simulator `.app` from your team/CI. Device/App Store builds
   and `.ipa` files are not simulator apps. Use a simulator runtime supported by your app's deployment target.
2. Install that build on the chosen simulator, or supply it as `app.build` inside the capture project and use the
   Mac app's setup check to install it. The current config does not accept an Xcode workspace/scheme build request.
3. Prepare one screen with synthetic data. Without SDK changes, use your app's existing demo/local state and links
   or recorded taps. A saved container snapshot is optional; check its limits below.
4. Capture one device/locale/appearance, inspect it, and export. Integrate the SDK only when explicit app cooperation
   would improve this flow. Optional prompts may still require manual setup without app changes.

For SDK integration, follow the [startup recipe](../README.md#install-and-start-early). In your own store, allowlist
fixture names, replace data deterministically, and handle unknown names visibly instead of silently loading a different
fixture. Keep fixture definitions and all overrides under `#if DEBUG`. Decide which normal repository/load path is
replaced; otherwise a normal refresh may immediately overwrite the fixture. No data is created by adding the package.

## Fixture readiness

`TrueFrame.fixtures { name in … }` is a synchronous call, not an async registration. The lifecycle is:
create app store → `TrueFrame.start()` → consume fixture request → publish ready app state → create views.
The example uses local in-memory values so this completes before any view appears.

If your app needs an asynchronous database import, the closure may initiate your app-owned loading operation,
but TrueFrame does **not** await it. Keep the UI in a loading state until it succeeds; only publish a stable content
identifier after the transaction and view data are ready. On failure, show an explicit error, never the ready ID.
End the capture flow with `waitFor` on that ready content, followed by the tool's normal settle check.
Do not block the main thread with a semaphore, or wait only for a tab bar/spinner disappearance. Use your app's
existing concurrency rules; the SDK supplies no cancellation, retry, completion or thread-hopping API.

## Links and accessibility identifiers

Prefer links that reach a deliberate destination from a fresh launch. For debug launch links, consume the link **after**
fixture data is ready. Validate scheme, host/path and known record IDs. Do not accept arbitrary account IDs or credentials
from links. The example accepts `-trueframe-link trailjournal://journal` and
`-trueframe-link trailjournal://trail/cedar-loop`, only in Debug. It has no OS URL scheme registration.

The Mac project's `links.launchArgument` tells link discovery/recording how to supply candidate links. Actual flows
still contain the launch arguments. A custom scheme sent with `openURL` can trigger a system confirmation dialog;
using a supported launch argument avoids that. For existing universal links, association setup still belongs to your app.

Assign identifiers such as `journal.trail.cedar-loop` to content/actions; avoid a translated label, SF Symbol name,
row index or generated UUID. Keep normal accessibility labels meaningful for people. Use `waitFor` on data that uniquely
identifies the destination. Compiler and host parser tests cannot prove how SwiftUI exposes these IDs at runtime;
inspect the accessibility tree during your own capture validation.

## Current Mac project surface

The example's [complete project.json](../Examples/TrailJournal/Capture/project.json) uses schema version 1.
Paths such as `app.build` and `output` are relative to the folder containing `project.json`.

| Location | Supported values relevant to this recipe |
| --- | --- |
| `app` | `bundleId`; optional `build`, a simulator `.app` path **inside** the capture folder |
| `devices.<slot>` | `udid`, or `simulator` name with optional `runtime`; optional `expectedSize: [width, height]` |
| `profiles.<name>` | `statusBar`, `contentSize`; optional `appClock` (see below) |
| `links` | `launchArgument`, for example `-trueframe-link` |
| `flows.<name>` | Ordered steps, starting with `launch`; each step has exactly one key |
| `sets.<name>` | `profile`, `locales`, `devices` (slot keys), `appearances`, `frames`; optional `package` |
| `sets.<name>.package` / `frames[].package` | Only `captureMode` (Boolean) and `fixtures` (name string) |
| `frames[]` | `name`, `flow`; optional `state` and per-frame `package` |
| `states.<name>` | `path` to an optional saved container snapshot |
| `output` | Capture directory, default `captures` |

A frame's specified package fields override the set's fields; unspecified fields inherit. To disable inherited capture
mode use `false`; to clear an inherited fixture use `""`. Neither a `clock` nor a `stubs` field belongs under `package`.
The environment can request a fixture independently of capture mode; app code chooses whether/how to honor it.

Supported flow steps are `launch` (`arguments`, `environment`), `openURL` (string), `waitFor` (element query),
`tap` (element query), `wait` (seconds) and `scrollTo` (query plus direction/swipes). Queries support `identifier`,
`label`, `labelContains`, `value`, `type`, `absent` and `timeout`; taps/scrolls require a present element.
There is no text-entry/password step in this recipe. Never put passwords, tokens or real account data in launch
environments, flow arguments, committed states or shareable capture projects.

For a separately available CLI on PATH:

```sh
trueframe validate -p Capture                         # schema/references, no runtime proof
trueframe devices                                   # available simulator inventory
trueframe check -p Capture                           # readiness and suggested fixes
trueframe run -p Capture --set app-store --frame journal
trueframe status -p Capture --set app-store
trueframe preflight -p Capture --set app-store
trueframe export -p Capture --set app-store --to Exports --format fastlane
```

`-p` takes a project folder or its `project.json`. `run` also supports `--locale`, `--device` (slot),
`--appearance light|dark`, and `--retry-clock`. The CLI operates on installed simulator apps; `app.build` supplies
an install candidate for the Mac setup UI and is not an automatic workspace/scheme build instruction.
`waitFor`, `tap` and `scrollTo` require the Mac tool's accessibility driver (AXe); the package does not provide it.
Preflight heuristics and settle checks do not replace inspecting the output for correctness or truncation.

## Clock, authentication and snapshots

- A status bar time changes the pixels in the status bar, not `Date()` or server time. The example does not read
  "now" at all: its local distances/durations stay the same without clock injection.
- Optional `profiles.<name>.appClock` is a separate Mac-side injected library, off by default. Supported settings
  are `"status-bar"`, a time such as `"9:41"`, or a local timestamp such as `"2026-01-13T09:41"`.
  `"status-bar"` requires a status bar time. A time of day uses its most recent occurrence to avoid moving ahead;
  moving backwards can still break clock guards and authentication. The SDK only reports a launch marker through
  `isClockSet`; it neither sets the clock nor establishes that all app/framework time sources obey it.
- If authentication breaks, remove `appClock` and re-establish the demo session through normal security rules.
  The Mac engine can keep clock injection disabled after detected sign-out; `--retry-clock` retries intentionally.
  Detection is heuristic and depends on screen/accessibility evidence; no automatic recovery is guaranteed.
  Do not weaken production token validation or clock/security checks to get a screenshot.
- `trueframe state save demo -p Capture --device phone --confirm-demo-data` snapshots app data and app-group
  containers. Confirm only after verifying the simulator holds synthetic data. Restoring with
  `trueframe state restore demo -p Capture --device phone` replaces local container data, so prepare accordingly.
  **Keychain is not included**: authentication state does not travel with the snapshot. Server state can change or
  overwrite restored local data on the next fetch. Cross-runtime restoration is not guaranteed, and relative dates age.
  Prefer the example's app-owned local fixture over snapshotting a live account.

## Optional coding-agent checklist

Give a coding agent your app's store initialization and navigation entry points, this package README and a copy of
`project.json`. Ask it to wire an allowlisted local fixture after `start()`, keep overrides under `#if DEBUG`, add
stable content IDs and validated links, then compile Debug and Release. Review the diff for accidental service calls
or security changes. It can edit the existing JSON and invoke an already available `trueframe validate` CLI.
No MCP server, telemetry or automatic data/translation capability is implied. Runtime capture is a separate check.
