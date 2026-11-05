// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrueFrame",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TrueFrame", targets: ["TrueFrame"]),
        // Existing integrations keep their product/import/API until they choose to migrate.
        .library(name: "AppShots", targets: ["AppShots"]),
    ],
    targets: [
        .target(name: "TrueFrame"),
        .target(name: "AppShots", dependencies: ["TrueFrame"]),
        .testTarget(name: "TrueFrameTests", dependencies: ["TrueFrame", "AppShots"]),
        // Host-side checks reuse the example's actual model/adapter without launching a simulator.
        .testTarget(
            name: "JournalExampleTests", dependencies: ["TrueFrame"], path: "Examples/TrailJournal",
            exclude: ["TrailJournal.xcodeproj", "README.md", "Capture", "App/ContentView.swift", "App/TrailJournalApp.swift"],
            sources: ["App/Journal.swift", "App/CaptureSetup.swift", "Tests/JournalTests.swift"]
        ),
    ]
)
