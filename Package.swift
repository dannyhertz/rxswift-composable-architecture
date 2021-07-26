// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "rxswift-composable-architecture",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ComposableArchitecture",
      targets: ["ComposableArchitecture"]
    ),
    .library(
      name: "ComposableCoreLocation",
      targets: ["ComposableCoreLocation"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.1.1"),
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0"),
  ],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: [
        "CasePaths", "RxSwift", "RxRelay",
      ]
    ),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: [
        "ComposableArchitecture", "RxTest",
      ]
    ),
    .target(
      name: "ComposableCoreLocation",
      dependencies: [
        "ComposableArchitecture"
      ]
    ),
    .testTarget(
      name: "ComposableCoreLocationTests",
      dependencies: [
        "ComposableCoreLocation"
      ]
    ),
  ]
)
