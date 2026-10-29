import Foundation
import XCTest
@testable import AppShots

final class AppShotsTests: XCTestCase {
    override func setUp() { AppShots.state = AppShots.State() }

    private func folder() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("appshots-package-\(UUID().uuidString)")
    }

    func testDoesNothingUnlessAppShotsLaunchedTheApp() {
        let handshake = folder()
        AppShots.start(environment: ["APPSHOTS_CAPTURE_MODE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(AppShots.isCapturing)
        XCTAssertFalse(FileManager.default.fileExists(atPath: handshake.path))
    }

    func testCaptureModeAndFixturesFollowTheLaunchSettings() throws {
        let handshake = folder()
        AppShots.start(environment: ["APPSHOTS_CAPTURE": "1", "APPSHOTS_CAPTURE_MODE": "1", "APPSHOTS_FIXTURES": "demo"],
                       handshakeFolder: handshake)
        XCTAssertTrue(AppShots.isCapturing)
        var loaded: String?
        AppShots.fixtures { loaded = $0 }
        XCTAssertEqual(loaded, "demo")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contents = try decoder.decode(Handshake.Contents.self,
                                          from: Data(contentsOf: handshake.appendingPathComponent("package.json")))
        XCTAssertEqual(contents.version, AppShots.version)
        XCTAssertTrue(contents.captureMode)
        XCTAssertEqual(contents.fixtureSet, "demo")
    }

    func testLaunchedButNotCapturingStillReportsThePackage() {
        let handshake = folder()
        AppShots.start(environment: ["APPSHOTS_CAPTURE": "1"], handshakeFolder: handshake)
        XCTAssertFalse(AppShots.isCapturing)
        XCTAssertNil(AppShots.fixtureSet)
        XCTAssertTrue(FileManager.default.fileExists(atPath: handshake.appendingPathComponent("package.json").path))
    }
}
