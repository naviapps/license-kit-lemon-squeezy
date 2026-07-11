// swift-tools-version: 6.0
import PackageDescription

func naviappsPackage(
  _ repository: String,
  localPathEnvironmentKey: String,
  from version: Version
) -> Package.Dependency {
  if let localPath = Context.environment[localPathEnvironmentKey], !localPath.isEmpty {
    return .package(path: localPath)
  }

  return .package(url: "https://github.com/naviapps/\(repository).git", from: version)
}

let package = Package(
  name: "LicenseKitLemonSqueezy",
  platforms: [
    .iOS(.v16),
    .macOS(.v14),
    .tvOS(.v16),
    .watchOS(.v9),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "LicenseKitLemonSqueezy",
      targets: ["LicenseKitLemonSqueezy"]
    )
  ],
  dependencies: [
    naviappsPackage(
      "license-kit",
      localPathEnvironmentKey: "LICENSE_KIT_PATH",
      from: "2.0.0"
    )
  ],
  targets: [
    .target(
      name: "LicenseKitLemonSqueezy",
      dependencies: [
        .product(name: "LicenseKit", package: "license-kit")
      ]
    ),
    .testTarget(
      name: "LicenseKitLemonSqueezyTests",
      dependencies: [
        "LicenseKitLemonSqueezy",
        .product(name: "LicenseKit", package: "license-kit"),
      ]
    ),
  ]
)
