// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "rxswift-composable-architecture",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "ComposableArchitecture",
            targets: ["ComposableArchitecture"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/tutu-ru-mobile/swift-case-paths", from: "0.1.2"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "ComposableArchitecture",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "RxRelay", package: "RxSwift"),
                "RxSwift"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ComposableArchitectureTests",
            dependencies: [
                "ComposableArchitecture",
                .product(name: "RxTest", package: "RxSwift")
            ],
            path: "Tests"
        )
    ]
)
