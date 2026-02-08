// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GherkinGenerator",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .macCatalyst(.v17)
    ],
    products: [
        .library(
            name: "GherkinGenerator",
            targets: ["GherkinGenerator"]
        ),
        .executable(
            name: "gherkin-gen",
            targets: ["GherkinGenCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .systemLibrary(
            name: "CZlib",
            path: "Sources/CZlib",
            providers: [
                .apt(["zlib1g-dev"]),
                .brew(["zlib"])
            ]
        ),
        .target(
            name: "GherkinGenerator",
            dependencies: ["CZlib"],
            path: "Sources/GherkinGenerator",
            resources: [.process("Resources")]
        ),
        .target(
            name: "GherkinGenCLICore",
            dependencies: [
                "GherkinGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GherkinGenCLICore"
        ),
        .executableTarget(
            name: "GherkinGenCLI",
            dependencies: ["GherkinGenCLICore"],
            path: "Sources/GherkinGenCLI"
        ),
        .testTarget(
            name: "GherkinGeneratorTests",
            dependencies: [
                "GherkinGenerator",
                "CZlib"
            ],
            path: "Tests/GherkinGeneratorTests",
            resources: [.process("Fixtures/Resources")]
        ),
        .testTarget(
            name: "GherkinGenCLITests",
            dependencies: [
                "GherkinGenCLICore",
                "GherkinGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Tests/GherkinGenCLITests"
        )
    ]
)
