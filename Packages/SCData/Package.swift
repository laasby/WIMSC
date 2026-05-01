// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SCData",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SCData", targets: ["SCData"]),
    ],
    targets: [
        .target(
            name: "SCData",
            path: "Sources/SCData",
            resources: [.process("Resources")]
        ),
    ]
)
