// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-functor",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [
        .library(name: "Representable Macro", targets: ["Representable Macro"]),
        .library(name: "Traversable Macro", targets: ["Traversable Macro"]),
        .library(name: "Traversal Support", targets: ["Traversal Support"]),
        .library(name: "Invariant Macro", targets: ["Invariant Macro"]),
        .library(name: "Functor Macro", targets: ["Functor Macro"]),
        .library(name: "Functor Base Macro", targets: ["Functor Base Macro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-foldable.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-finite.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-algebra.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-product.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.2"..<"604.0.0")
    ],
    targets: [
        .testTarget(name: "Representable Macro Tests", dependencies: [
            .target(name: "Representable Macro"),
            .target(name: "Functor Macro"),
        ]),
        .testTarget(name: "Traversable Macro Tests", dependencies: [
            .target(name: "Traversable Macro"),
            .target(name: "Functor Macro"),
            .product(name: "Foldable Macro", package: "swift-foldable"),
        ]),
        .testTarget(name: "Algebra Consumer Tests", dependencies: [
            .product(name: "Cardinal", package: "swift-cardinal"),
            .target(name: "Algebra Consumer Fixtures"),
        ]),
        .target(name: "Algebra Consumer Fixtures", dependencies: [
            .target(name: "Functor Macro"),
            .target(name: "Traversable Macro"),
            .target(name: "Representable Macro"),
        ]),
        .testTarget(name: "Invariant Macro Tests", dependencies: [
            .target(name: "Invariant Macro"),
            .product(name: "Algebra Test Support", package: "swift-algebra"),
        ]),
        .target(name: "Representable Macro", dependencies: [
            .target(name: "Representable Macro Plugin"),
            .product(name: "Finite Macro", package: "swift-finite"),
        ]),
        .macro(name: "Representable Macro Plugin", dependencies: [
            .target(name: "Representable Macro Core"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]),
        .target(name: "Representable Macro Core", dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            .product(name: "Type Algebra Syntax", package: "swift-algebra"),
        ]),
        .target(name: "Traversable Macro", dependencies: [
            .target(name: "Traversable Macro Plugin"),
            .target(name: "Traversal Support"),
        ]),
        .macro(name: "Traversable Macro Plugin", dependencies: [
            .target(name: "Traversable Macro Core"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]),
        .target(name: "Traversable Macro Core", dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            .product(name: "Type Algebra Syntax", package: "swift-algebra"),
        ]),
        .target(name: "Traversal Support", dependencies: [
        ]),
        .target(name: "Invariant Macro", dependencies: [
            .target(name: "Invariant Macro Plugin"),
        ]),
        .macro(name: "Invariant Macro Plugin", dependencies: [
            .target(name: "Invariant Macro Core"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]),
        .target(name: "Invariant Macro Core", dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            .product(name: "Type Algebra Syntax", package: "swift-algebra"),
        ]),
        .target(
            name: "Functor Macro Core",
            dependencies: [
                .product(name: "Type Algebra Syntax", package: "swift-algebra"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "Functor Macro Plugin",
            dependencies: [
                .target(name: "Functor Macro Core"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Functor Macro",
            dependencies: [.target(name: "Functor Macro Plugin")]
        ),
        .testTarget(
            name: "Functor Macro Tests",
            dependencies: [
            .product(name: "Algebra Test Support", package: "swift-algebra"),.target(name: "Functor Macro")]
        ),
        .target(
            name: "Functor Base Macro Core",
            dependencies: [
            .product(name: "Type Algebra Syntax", package: "swift-algebra"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "Functor Base Macro Plugin",
            dependencies: [
                .target(name: "Functor Base Macro Core"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Functor Base Macro",
            dependencies: [
                .target(name: "Functor Macro"),.target(name: "Functor Base Macro Plugin")]
        ),
        .testTarget(
            name: "Functor Base Macro Tests",
            dependencies: [.target(name: "Functor Base Macro")]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableExperimentalFeature("Lifetimes"),
        .treatAllWarnings(as: .error),
    ]
}
