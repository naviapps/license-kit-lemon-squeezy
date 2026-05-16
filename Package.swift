// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LicenseKitLemonSqueezy",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "LicenseKitLemonSqueezy",
      targets: ["LicenseKitLemonSqueezy"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/naviapps/license-kit.git", from: "1.2.0")
  ],

  targets: [
    .target(
      name: "LicenseKitLemonSqueezy",
      dependencies: [
        .product(name: "LicenseKit", package: "license-kit")
      ],
      path: "Sources/LicenseKitLemonSqueezy"
    ),
    .testTarget(
      name: "LicenseKitLemonSqueezyTests",
      dependencies: ["LicenseKitLemonSqueezy"],
      path: "Tests/LicenseKitLemonSqueezyTests"
    ),
  ],
  swiftLanguageVersions: [.v5]
)
