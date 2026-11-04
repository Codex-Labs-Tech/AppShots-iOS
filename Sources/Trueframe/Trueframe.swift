import Foundation

/// Lets an app cooperate with Trueframe while its App Store screenshots are captured.
///
/// Add one line to your app, in a debug build only:
///
///     #if DEBUG
///     Trueframe.start()
///     #endif
///
/// Nothing happens unless Trueframe launches the app, and then only what the Trueframe project turns on. In a
/// release build the package compiles to empty stubs: `isCapturing` is always false.
public enum Trueframe {
    /// This package's version, reported to Trueframe.
    public static let version = "0.1.0"

    /// True while Trueframe is capturing with capture mode on. Use it to skip anything that would get in the way of
    /// a screenshot: permission and biometric prompts, onboarding, review requests, tips, debug banners.
    public static var isCapturing: Bool { state.isCapturing }

    /// The fixture set Trueframe asked for, if any: load that demo data instead of the usual source.
    public static var fixtureSet: String? { state.fixtureSet }

    /// True when Trueframe has set this app's clock to a fixed time of day (its `appClock` setting), so dates read the
    /// same every run. If your app ends sessions when the clock moves (a guard against people changing the time),
    /// skip that guard while this is true: Trueframe moved it on purpose. See the README.
    public static var isClockSet: Bool { state.isClockSet }

    /// Reads Trueframe' launch settings and tells Trueframe the package is here. Call it once, early, in debug builds.
    public static func start() {
        start(environment: ProcessInfo.processInfo.environment)
    }

    /// Calls `load` with the requested fixture set, if Trueframe asked for one. Call it where your app sets up its
    /// data, after `start()`.
    public static func fixtures(_ load: (String) -> Void) {
        if let set = fixtureSet { load(set) }
    }

    // MARK: Internals

    struct State: Equatable {
        var launchedByTrueframe = false
        var isCapturing = false
        var fixtureSet: String?
        var isClockSet = false
    }

    #if DEBUG
    nonisolated(unsafe) static var state = State()
    #else
    static var state: State { State() }
    #endif

    /// The launch settings Trueframe passes, as environment variables.
    enum Key {
        /// Present on every launch Trueframe makes.
        static let launched = "APPSHOTS_CAPTURE"
        static let captureMode = "APPSHOTS_CAPTURE_MODE"
        static let fixtures = "APPSHOTS_FIXTURES"
        /// Set by Trueframe when it loads its clock library into the app.
        static let clockStart = "APPSHOTS_CLOCK_START"
    }

    static func start(environment: [String: String], handshakeFolder: URL? = nil) {
        #if DEBUG
        guard environment[Key.launched] == "1" else { return }
        state = State(launchedByTrueframe: true,
                      isCapturing: environment[Key.captureMode] == "1",
                      fixtureSet: environment[Key.fixtures].flatMap { $0.isEmpty ? nil : $0 },
                      isClockSet: environment[Key.clockStart] != nil)
        Handshake.write(state, to: handshakeFolder ?? Handshake.defaultFolder)
        #endif
    }
}

/// A small file in the app's own data folder that tells Trueframe which version of the package is in the build and
/// what it was asked to do. Trueframe reads app data folders anyway, so it needs nothing else to detect the package.
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

    static func write(_ state: Trueframe.State, to folder: URL, now: Date = Date()) {
        let contents = Contents(version: Trueframe.version, features: ["captureMode", "fixtures", "clock"],
                                captureMode: state.isCapturing, fixtureSet: state.fixtureSet, clockSet: state.isClockSet,
                                startedAt: now)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try encoder.encode(contents).write(to: folder.appendingPathComponent(fileName), options: .atomic)
        } catch {
            // Detection only: Trueframe will report the package as missing, which is the right outcome.
        }
    }
}
