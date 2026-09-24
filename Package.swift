// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MacClipboard",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "MacClipboard",
            targets: ["MacClipboard"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacClipboard",
            path: "Sources/MacClipboard"
        )
    ]
)
