// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LampControl",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LampControl", targets: ["LampControl"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "LampControl",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/LampControl",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
