import Foundation
import AppShots
import XCTest
@testable import TrueFrame

final class TrueFrameTests: XCTestCase {
    override func setUp() { TrueFrame.state = TrueFrame.State() }

    func testLegacyProductAndAPIShareCaptureStateAndFixtures() {
        let handshake = folder()
        defer { try? FileManager.default.removeItem(at: handshake) }
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1", "APPSHOTS_FIXTURES": "demo"],
                        handshakeFolder: handshake)
        XCTAssertEqual(AppShots.version, TrueFrame.version)
        XCTAssertTrue(AppShots.isCapturing)
        var legacyFixture: String?
        AppShots.fixtures { legacyFixture = $0 }
        XCTAssertEqual(legacyFixture, TrueFrame.fixtureSet)
        XCTAssertEqual(Handshake.defaultFolder.lastPathComponent, "AppShots")
    }

    private func folder() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("trueframe-package-\(UUID().uuidString)")
    }

    func testDoesNothingUnlessTrueFrameLaunchedTheApp() {
        let handshake = folder()
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE_MODE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(TrueFrame.isCapturing)
        XCTAssertFalse(FileManager.default.fileExists(atPath: handshake.path))
    }

    func testCaptureModeAndFixturesFollowTheLaunchSettings() throws {
        let handshake = folder()
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1", "APPSHOTS_FIXTURES": "demo"],
                       handshakeFolder: handshake)
        XCTAssertTrue(TrueFrame.isCapturing)
        var loaded: String?
        TrueFrame.fixtures { loaded = $0 }
        XCTAssertEqual(loaded, "demo")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contents = try decoder.decode(Handshake.Contents.self,
                                          from: Data(contentsOf: handshake.appendingPathComponent("package.json")))
        XCTAssertEqual(contents.version, TrueFrame.version)
        XCTAssertTrue(contents.captureMode)
        XCTAssertEqual(contents.fixtureSet, "demo")
    }

    func testKnowsWhenTrueFrameSetTheClock() {
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1"], handshakeFolder: folder())
        XCTAssertFalse(TrueFrame.isClockSet)
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CLOCK_START": "1800000000"], handshakeFolder: folder())
        XCTAssertTrue(TrueFrame.isClockSet)
        // The clock variable alone, without an TrueFrame launch, means nothing.
        TrueFrame.state = TrueFrame.State()
        TrueFrame.start(environment: ["APPSHOTS_CLOCK_START": "1800000000"], handshakeFolder: folder())
        XCTAssertFalse(TrueFrame.isClockSet)
    }

    func testLaunchedButNotCapturingStillReportsThePackage() {
        let handshake = folder()
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(TrueFrame.isCapturing)
        XCTAssertNil(TrueFrame.fixtureSet)
        XCTAssertTrue(FileManager.default.fileExists(atPath: handshake.appendingPathComponent("package.json").path))
    }
}
