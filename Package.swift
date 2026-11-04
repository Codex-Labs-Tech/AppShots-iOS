// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Trueframe",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Trueframe", targets: ["Trueframe"]),
        // Existing integrations keep their product/import/API until they choose to migrate.
        .library(name: "AppShots", targets: ["AppShots"]),
    ],
    targets: [
        .target(name: "Trueframe"),
        .target(name: "AppShots", dependencies: ["Trueframe"]),
        .testTarget(name: "TrueframeTests", dependencies: ["Trueframe", "AppShots"]),
    ]
)
