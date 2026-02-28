// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkOwl",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LinkOwl",
            targets: ["LinkOwl"]
        )
    ],
    targets: [
        .target(
            name: "LinkOwl",
            path: "Sources/LinkOwl",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "LinkOwlTests",
            dependencies: ["LinkOwl"],
            path: "Tests/LinkOwlTests"
        )
    ]
)
