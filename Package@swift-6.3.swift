// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-uitesting",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "UITesting", targets: ["UITesting"]),
        .library(name: "UITestingCore", targets: ["UITestingCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"605.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", "0.7.0"..<"1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", "1.0.0"..<"2.0.0")
    ],
    targets: [
        .target(name: "UITestingCore"),
        .target(
            name: "UITesting",
            dependencies: [
                "UITestingCore",
                "UITestingMacros",
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]
        ),
        .macro(
            name: "UITestingMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "UITestingCoreTests",
            dependencies: ["UITestingCore"]
        ),
        .testTarget(
            name: "UITestingTests",
            dependencies: ["UITesting"]
        ),
        .testTarget(
            name: "UITestingMacrosTests",
            dependencies: [
                "UITestingMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax")
            ]
        )
    ]
)
