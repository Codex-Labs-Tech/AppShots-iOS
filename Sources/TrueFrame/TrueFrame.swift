import Foundation

/// Lets an app cooperate with TrueFrame while its App Store screenshots are captured.
///
/// Add one line to your app, in a debug build only:
///
///     #if DEBUG
///     TrueFrame.start()
///     #endif
///
/// In Debug, activation requires `APPSHOTS_CAPTURE=1`; callers can also supply that environment manually for testing.
/// In Release, capture state is inactive and `start()` does nothing. The app owns its fixture data and UI decisions.
public enum TrueFrame {
    /// This package's version, reported to TrueFrame.
    public static let version = "0.1.0"

    /// True during a Debug launch with capture mode requested. App code may suppress optional tips or review prompts.
    /// This is not an authorization signal: do not use it to grant access to real accounts or protected data.
    public static var isCapturing: Bool { state.isCapturing }

    /// The fixture set TrueFrame asked for, if any: load that demo data instead of the usual source.
    public static var fixtureSet: String? { state.fixtureSet }

    /// True in Debug when a capture launch includes the clock-injection marker. This package does not set time.
    /// An injected app clock can invalidate authentication; leave it off for real sessions. See the README.
    public static var isClockSet: Bool { state.isClockSet }

    /// Reads TrueFrame's launch settings and writes its detection file. Call once, early, in debug builds.
    public static func start() {
        start(environment: ProcessInfo.processInfo.environment)
    }

    /// Calls `load` immediately and synchronously with the requested fixture name, if any, after `start()`.
    /// This does not retain a callback, generate data, await work, or check whether the app recognizes the name.
    public static func fixtures(_ load: (String) -> Void) {
        if let set = fixtureSet { load(set) }
    }

    // MARK: Internals

    struct State: Equatable {
        var launchedByTrueFrame = false
        var isCapturing = false
        var fixtureSet: String?
        var isClockSet = false
    }

    #if DEBUG
    nonisolated(unsafe) static var state = State()
    #else
    static var state: State { State() }
    #endif

    /// The launch settings TrueFrame passes, as environment variables.
    enum Key {
        /// Present on every launch TrueFrame makes.
        static let launched = "APPSHOTS_CAPTURE"
        static let captureMode = "APPSHOTS_CAPTURE_MODE"
        static let fixtures = "APPSHOTS_FIXTURES"
        /// Set by TrueFrame when it loads its clock library into the app.
        static let clockStart = "APPSHOTS_CLOCK_START"
    }

    static func start(environment: [String: String], handshakeFolder: URL? = nil) {
        #if DEBUG
        guard environment[Key.launched] == "1" else { return }
        state = State(launchedByTrueFrame: true,
                      isCapturing: environment[Key.captureMode] == "1",
                      fixtureSet: environment[Key.fixtures].flatMap { $0.isEmpty ? nil : $0 },
                      isClockSet: environment[Key.clockStart] != nil)
        Handshake.write(state, to: handshakeFolder ?? Handshake.defaultFolder)
        #endif
    }
}

/// A small file in the app's own data folder that tells TrueFrame which version of the package is in the build and
/// what it was asked to do. TrueFrame reads app data folders anyway, so it needs nothing else to detect the package.
enum Handshake {
    static let fileName = "package.json"

    static var defaultFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppShots", isDirectory: true)
    }

    struct Contents: Codable, Equatable {
        var version: String
        var features: [String]
        var captureMode: Bool
        var fixtureSet: String?
        var clockSet: Bool
        var startedAt: Date
    }

    static func write(_ state: TrueFrame.State, to folder: URL, now: Date = Date()) {
        let contents = Contents(version: TrueFrame.version, features: ["captureMode", "fixtures", "clock"],
                                captureMode: state.isCapturing, fixtureSet: state.fixtureSet, clockSet: state.isClockSet,
                                startedAt: now)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try encoder.encode(contents).write(to: folder.appendingPathComponent(fileName), options: .atomic)
        } catch {
            // Detection only: TrueFrame will report the package as missing, which is the right outcome.
        }
    }
}
