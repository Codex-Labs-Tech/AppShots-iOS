import Foundation

/// Lets an app cooperate with AppShots while its App Store screenshots are captured.
///
/// Add one line to your app, in a debug build only:
///
///     #if DEBUG
///     AppShots.start()
///     #endif
///
/// Nothing happens unless AppShots launches the app, and then only what the AppShots project turns on. In a
/// release build the package compiles to empty stubs: `isCapturing` is always false.
public enum AppShots {
    /// This package's version, reported to AppShots.
    public static let version = "0.1.0"

    /// True while AppShots is capturing with capture mode on. Use it to skip anything that would get in the way of
    /// a screenshot: permission and biometric prompts, onboarding, review requests, tips, debug banners.
    public static var isCapturing: Bool { state.isCapturing }

    /// The fixture set AppShots asked for, if any: load that demo data instead of the usual source.
    public static var fixtureSet: String? { state.fixtureSet }

    /// Reads AppShots' launch settings and tells AppShots the package is here. Call it once, early, in debug builds.
    public static func start() {
        start(environment: ProcessInfo.processInfo.environment)
    }

    /// Calls `load` with the requested fixture set, if AppShots asked for one. Call it where your app sets up its
    /// data, after `start()`.
    public static func fixtures(_ load: (String) -> Void) {
        if let set = fixtureSet { load(set) }
    }

    // MARK: Internals

    struct State: Equatable {
        var launchedByAppShots = false
        var isCapturing = false
        var fixtureSet: String?
    }

    #if DEBUG
    nonisolated(unsafe) static var state = State()
    #else
    static var state: State { State() }
    #endif

    /// The launch settings AppShots passes, as environment variables.
    enum Key {
        /// Present on every launch AppShots makes.
        static let launched = "APPSHOTS_CAPTURE"
        static let captureMode = "APPSHOTS_CAPTURE_MODE"
        static let fixtures = "APPSHOTS_FIXTURES"
    }

    static func start(environment: [String: String], handshakeFolder: URL? = nil) {
        #if DEBUG
        guard environment[Key.launched] == "1" else { return }
        state = State(launchedByAppShots: true,
                      isCapturing: environment[Key.captureMode] == "1",
                      fixtureSet: environment[Key.fixtures].flatMap { $0.isEmpty ? nil : $0 })
        Handshake.write(state, to: handshakeFolder ?? Handshake.defaultFolder)
        #endif
    }
}

/// A small file in the app's own data folder that tells AppShots which version of the package is in the build and
/// what it was asked to do. AppShots reads app data folders anyway, so it needs nothing else to detect the package.
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
        var startedAt: Date
    }

    static func write(_ state: AppShots.State, to folder: URL, now: Date = Date()) {
        let contents = Contents(version: AppShots.version, features: ["captureMode", "fixtures"],
                                captureMode: state.isCapturing, fixtureSet: state.fixtureSet, startedAt: now)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try encoder.encode(contents).write(to: folder.appendingPathComponent(fileName), options: .atomic)
        } catch {
            // Detection only: AppShots will report the package as missing, which is the right outcome.
        }
    }
}
