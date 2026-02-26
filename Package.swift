// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WinKeys",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "WinKeysLib",
            path: "Sources/WinKeysLib",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .executableTarget(
            name: "WinKeys",
            dependencies: ["WinKeysLib"],
            path: "Sources/WinKeys",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "WinKeysTests",
            dependencies: [
                "WinKeysLib",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/WinKeysTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
