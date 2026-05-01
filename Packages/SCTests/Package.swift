// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SCTests",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(path: "../SCDomain"),
    ],
    targets: [
        .testTarget(
            name: "SCTests",
            dependencies: ["SCDomain"],
            path: "Tests/SCTests"
        ),
    ]
)
