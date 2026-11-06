import Foundation
import XCTest

final class JournalTests: XCTestCase {
    #if DEBUG
    func testNamedFixtureIsRepeatableAndUnknownFixturePreservesData() {
        var journal = Journal()
        XCTAssertFalse(journal.loadFixture(named: "unknown"))
        XCTAssertTrue(journal.trails.isEmpty)
        XCTAssertTrue(journal.loadFixture(named: "weekend-hikes"))
        let entries = journal.trails
        XCTAssertEqual(entries.map(\.id), ["cedar-loop", "willow-lake", "meadow-path"])
        XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
        XCTAssertTrue(journal.loadFixture(named: "weekend-hikes"))
        XCTAssertEqual(journal.trails, entries)
        XCTAssertFalse(journal.loadFixture(named: "Weekend-Hikes"))
        XCTAssertEqual(journal.trails, entries)
    }

    func testLinksRequireExactDestinationsAndLoadedData() throws {
        var journal = Journal()
        let detail = try XCTUnwrap(URL(string: "trailjournal://trail/cedar-loop"))
        XCTAssertNil(JournalRoute(url: detail, journal: journal))
        journal.loadFixture(named: "weekend-hikes")
        XCTAssertEqual(JournalRoute(url: detail, journal: journal), .trail("cedar-loop"))
        XCTAssertEqual(JournalRoute(url: try XCTUnwrap(URL(string: "trailjournal://journal")), journal: journal), .journal)
        for invalid in ["https://trail/cedar-loop", "trailjournal://other", "trailjournal://trail/missing",
                        "trailjournal://trail/cedar-loop/extra", "trailjournal://trail/cedar-loop?token=secret",
                        "trailjournal://user@trail/cedar-loop", "trailjournal://trail:42/cedar-loop",
                        "trailjournal://trail/cedar-loop#note", "trailjournal://trail/%63edar-loop",
                        "trailjournal://journal/extra"] {
            XCTAssertNil(JournalRoute(url: try XCTUnwrap(URL(string: invalid)), journal: journal), invalid)
        }
    }

    func testLaunchArgumentValidation() {
        var journal = Journal()
        journal.loadFixture(named: "weekend-hikes")
        XCTAssertEqual(CaptureSetup.launchRoute(arguments: ["App", "-trueframe-link", "trailjournal://trail/cedar-loop"],
                                               journal: journal), .trail("cedar-loop"))
        for arguments in [["App"], ["App", "-trueframe-link"], ["App", "-trueframe-link", "bad"],
                          ["App", "-trueframe-link", "trailjournal://journal", "-trueframe-link", "trailjournal://journal"]] {
            XCTAssertNil(CaptureSetup.launchRoute(arguments: arguments, journal: journal))
        }
    }
    #endif

    func testNormalLaunchAndReleaseDoNotLoadDemoData() {
        // No SDK launch marker in Debug. Release also receives every capture flag and a valid debug link.
        let values = ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1",
                      "APPSHOTS_FIXTURES": "weekend-hikes", "APPSHOTS_CLOCK_START": "1800000000"]
        let original = ProcessInfo.processInfo.environment
        defer {
            for key in values.keys {
                if let value = original[key] { setenv(key, value, 1) } else { unsetenv(key) }
            }
        }
        for (key, value) in values { setenv(key, value, 1) }
        #if DEBUG
        unsetenv("APPSHOTS_CAPTURE")
        let arguments = ["App"]
        #else
        let arguments = ["App", "-trueframe-link", "trailjournal://trail/cedar-loop"]
        #endif
        var journal = Journal()
        let presentation = CaptureSetup.prepare(journal: &journal, arguments: arguments)
        XCTAssertTrue(journal.trails.isEmpty)
        XCTAssertTrue(presentation.showsTip)
        XCTAssertNil(presentation.fixtureIssue)
        XCTAssertEqual(presentation.route, .journal)
    }
}
