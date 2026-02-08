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
        .target(
            name: "GherkinGenerator",
            path: "Sources/GherkinGenerator",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "GherkinGenCLI",
            dependencies: [
                "GherkinGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GherkinGenCLI"
        ),
        .testTarget(
            name: "GherkinGeneratorTests",
            dependencies: ["GherkinGenerator"],
            path: "Tests/GherkinGeneratorTests",
            resources: [.process("Fixtures/Resources")]
        ),
        .testTarget(
            name: "GherkinGenCLITests",
            dependencies: [
                "GherkinGenCLI",
                "GherkinGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Tests/GherkinGenCLITests"
        )
    ]
)
