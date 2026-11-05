import Foundation
import AppShots
import XCTest
@testable import TrueFrame

final class TrueFrameTests: XCTestCase {
    #if DEBUG
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
        XCTAssertEqual(contents.version, "0.1.0")
        XCTAssertEqual(contents.features, ["captureMode", "fixtures", "clock"])
        XCTAssertFalse(contents.clockSet)
        XCTAssertTrue(contents.captureMode)
        XCTAssertEqual(contents.fixtureSet, "demo")
    }

    func testFixtureHookIsImmediateNotRetainedAndIndependentOfCaptureMode() {
        let handshake = folder()
        defer { try? FileManager.default.removeItem(at: handshake) }
        var calls: [String] = []
        TrueFrame.fixtures { calls.append($0) }
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_FIXTURES": "unknown-to-sdk"],
                        handshakeFolder: handshake)
        XCTAssertTrue(calls.isEmpty, "A pre-start hook is not retained")
        XCTAssertFalse(TrueFrame.isCapturing)
        TrueFrame.fixtures { calls.append($0) }
        XCTAssertEqual(calls, ["unknown-to-sdk"], "The hook runs inline; app code validates the name")
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_FIXTURES": ""], handshakeFolder: handshake)
        XCTAssertNil(TrueFrame.fixtureSet)
        TrueFrame.fixtures { _ in XCTFail("An empty fixture must not invoke the hook") }
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
    #else
    func testReleaseIgnoresEveryCaptureSettingAndDoesNotWriteHandshake() {
        let handshake = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        TrueFrame.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1",
                                     "APPSHOTS_FIXTURES": "demo", "APPSHOTS_CLOCK_START": "1800000000"],
                        handshakeFolder: handshake)
        XCTAssertFalse(TrueFrame.isCapturing)
        XCTAssertFalse(AppShots.isCapturing)
        XCTAssertFalse(TrueFrame.isClockSet)
        XCTAssertNil(TrueFrame.fixtureSet)
        TrueFrame.fixtures { _ in XCTFail("Release must not call the fixture hook") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: handshake.path))
    }
    #endif
}
