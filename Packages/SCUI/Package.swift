// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SCUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SCUI", targets: ["SCUI"]),
    ],
    dependencies: [
        .package(path: "../SCDomain"),
    ],
    targets: [
        .target(
            name: "SCUI",
            dependencies: ["SCDomain"],
            path: "Sources/SCUI"
        ),
    ]
)
