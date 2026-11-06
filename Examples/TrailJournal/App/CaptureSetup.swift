import Foundation
#if DEBUG
import TrueFrame
#endif

/// Presentation choices made by this app, rather than by the SDK.
struct CapturePresentation {
    var showsTip = true
    var route = JournalRoute.journal
    var fixtureIssue: String?
}

/// Prepares local data before SwiftUI creates its first view.
enum CaptureSetup {
    /// Starts the SDK, loads the requested fixture synchronously, then resolves a debug launch link.
    static func prepare(journal: inout Journal, arguments: [String] = CommandLine.arguments) -> CapturePresentation {
        var presentation = CapturePresentation()
        #if DEBUG
        TrueFrame.start()
        TrueFrame.fixtures { name in
            if !journal.loadFixture(named: name) {
                presentation.fixtureIssue = "Unknown fixture: \(name)"
            }
        }
        // Only a harmless local tip is suppressed. There is no auth or security decision here.
        presentation.showsTip = !TrueFrame.isCapturing
        if let route = launchRoute(arguments: arguments, journal: journal) {
            presentation.route = route
        }
        #endif
        return presentation
    }

    #if DEBUG
    /// Reads one explicit launch link. Malformed, repeated and unknown links are ignored.
    static func launchRoute(arguments: [String], journal: Journal) -> JournalRoute? {
        let indices = arguments.indices.filter { arguments[$0] == "-trueframe-link" }
        guard indices.count == 1, let index = indices.first, arguments.indices.contains(index + 1),
              let url = URL(string: arguments[index + 1]) else { return nil }
        return JournalRoute(url: url, journal: journal)
    }
    #endif
}
