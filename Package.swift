// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DockMate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DockMate", targets: ["DockMate"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DockMate",
            dependencies: [],
            path: "Sources/DockMate"
        )
    ]
)
