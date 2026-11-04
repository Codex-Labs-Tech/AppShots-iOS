import Foundation
import AppShots
import XCTest
@testable import Trueframe

final class TrueframeTests: XCTestCase {
    override func setUp() { Trueframe.state = Trueframe.State() }

    func testLegacyProductAndAPIShareCaptureStateAndFixtures() {
        let handshake = folder()
        defer { try? FileManager.default.removeItem(at: handshake) }
        Trueframe.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1", "APPSHOTS_FIXTURES": "demo"],
                        handshakeFolder: handshake)
        XCTAssertEqual(AppShots.version, Trueframe.version)
        XCTAssertTrue(AppShots.isCapturing)
        var legacyFixture: String?
        AppShots.fixtures { legacyFixture = $0 }
        XCTAssertEqual(legacyFixture, Trueframe.fixtureSet)
        XCTAssertEqual(Handshake.defaultFolder.lastPathComponent, "AppShots")
    }

    private func folder() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("trueframe-package-\(UUID().uuidString)")
    }

    func testDoesNothingUnlessTrueframeLaunchedTheApp() {
        let handshake = folder()
        Trueframe.start(environment: ["APPSHOTS_CAPTURE_MODE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(Trueframe.isCapturing)
        XCTAssertFalse(FileManager.default.fileExists(atPath: handshake.path))
    }

    func testCaptureModeAndFixturesFollowTheLaunchSettings() throws {
        let handshake = folder()
        Trueframe.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1", "APPSHOTS_FIXTURES": "demo"],
                       handshakeFolder: handshake)
        XCTAssertTrue(Trueframe.isCapturing)
        var loaded: String?
        Trueframe.fixtures { loaded = $0 }
        XCTAssertEqual(loaded, "demo")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contents = try decoder.decode(Handshake.Contents.self,
                                          from: Data(contentsOf: handshake.appendingPathComponent("package.json")))
        XCTAssertEqual(contents.version, Trueframe.version)
        XCTAssertTrue(contents.captureMode)
        XCTAssertEqual(contents.fixtureSet, "demo")
    }

    func testKnowsWhenTrueframeSetTheClock() {
        Trueframe.start(environment: ["APPSHOTS_CAPTURE": "1"], handshakeFolder: folder())
        XCTAssertFalse(Trueframe.isClockSet)
        Trueframe.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CLOCK_START": "1800000000"], handshakeFolder: folder())
        XCTAssertTrue(Trueframe.isClockSet)
        // The clock variable alone, without an Trueframe launch, means nothing.
        Trueframe.state = Trueframe.State()
        Trueframe.start(environment: ["APPSHOTS_CLOCK_START": "1800000000"], handshakeFolder: folder())
        XCTAssertFalse(Trueframe.isClockSet)
    }

    func testLaunchedButNotCapturingStillReportsThePackage() {
        let handshake = folder()
        Trueframe.start(environment: ["APPSHOTS_CAPTURE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(Trueframe.isCapturing)
        XCTAssertNil(Trueframe.fixtureSet)
        XCTAssertTrue(FileManager.default.fileExists(atPath: handshake.appendingPathComponent("package.json").path))
    }
}
