// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppShots",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AppShots", targets: ["AppShots"]),
    ],
    targets: [
        .target(name: "AppShots"),
        .testTarget(name: "AppShotsTests", dependencies: ["AppShots"]),
    ]
)
