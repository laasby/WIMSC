// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SCDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SCDomain", targets: ["SCDomain"]),
    ],
    dependencies: [
        .package(path: "../SCData"),
    ],
    targets: [
        .target(
            name: "SCDomain",
            dependencies: ["SCData"],
            path: "Sources/SCDomain"
        ),
    ]
)
