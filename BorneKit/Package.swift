// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BorneKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BorneCore", targets: ["BorneCore"]),
        .library(name: "BorneDesigns", targets: ["BorneDesigns"]),
    ],
    targets: [
        .target(name: "BorneCore"),
        .target(name: "BorneDesigns", dependencies: ["BorneCore"]),
        .testTarget(
            name: "BorneCoreTests",
            dependencies: ["BorneCore"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "BorneDesignsTests", dependencies: ["BorneDesigns", "BorneCore"]),
    ]
)
