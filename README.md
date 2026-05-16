# LicenseKitLemonSqueezy

[![CI](https://github.com/naviapps/license-kit-lemon-squeezy/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/license-kit-lemon-squeezy/actions/workflows/ci.yml)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Flicense-kit-lemon-squeezy%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy)
[![Supported platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Flicense-kit-lemon-squeezy%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

LicenseKitLemonSqueezy is the Lemon Squeezy license-key provider package for
[LicenseKit](https://github.com/naviapps/license-kit). It connects LicenseKit to
Lemon Squeezy license activation, validation, and deactivation without becoming a
general Lemon Squeezy SDK.

It intentionally does not include checkout, pricing, offerings, customer portal,
webhooks, or store-wide Lemon Squeezy API access. Keep those flows in your app,
backend, or a separate package.

## Requirements

- iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1, or later
- Swift 5.10 or later

## Installation

Add the packages with Swift Package Manager:

```swift
.package(url: "https://github.com/naviapps/license-kit.git", from: "1.2.0"),
.package(url: "https://github.com/naviapps/license-kit-lemon-squeezy.git", from: "1.0.0")
```

Then depend on the products:

```swift
.product(name: "LicenseKit", package: "license-kit"),
.product(name: "LicenseKitLemonSqueezy", package: "license-kit-lemon-squeezy")
```

## Usage

Use `LemonSqueezyLicenseProvider` as the `LicenseProvider` for distributed
Apple apps. LicenseKit owns state, storage, refresh policy, and the public
licensing state your UI reads.

```swift
import LicenseKit
import LicenseKitLemonSqueezy

let provider = LemonSqueezyLicenseProvider(
  configuration: LemonSqueezyLicenseConfiguration(
    activationInstanceName: "Example App",
    licenseScope: LemonSqueezyLicenseScope(
      storeID: "123",
      productID: "456",
      variantIDs: ["789"]
    )
  )
)

let licenseManager = LicenseManager(
  provider: provider,
  activationStorage: KeychainLicenseActivationStorage(
    service: "com.example.app.license",
    account: "activation"
  ),
  stateSnapshotStorage: UserDefaultsLicenseStateSnapshotStorage(
    storageKey: "com.example.app.license.snapshot"
  )
)

try await licenseManager.activate(.licenseKey(licenseKey))

if licenseManager.isLicensed {
  // Enable licensed app behavior.
}
```

`LicenseManager` restores persisted activations from `activationStorage` during
initialization. Restoring from storage does not contact Lemon Squeezy by itself;
call `refresh()` after launch when the restored activation must be validated
before you treat it as current.

```swift
if licenseManager.needsRefresh() {
  try await licenseManager.refresh()
}
```

## License API

Lemon Squeezy's license activation, validation, and deactivation endpoints use
the license key submitted by the user. They do not require a store-wide Lemon
Squeezy API key. Deactivation requires the activation identifier returned by
Lemon Squeezy when the license key is activated.

Validation results expose Lemon Squeezy variant IDs as `planID` when the license
API returns them. Configure `licenseScope` to reject license keys issued for
another Lemon Squeezy store, product, or variant. Call
`LicenseManager.deactivate()` when the activation should be removed, such as
during sign-out or device transfer.

Lemon Squeezy rate limits the License API. The provider retries `429` and
server-error responses with `Retry-After` support and exponential backoff, but
apps should still avoid tight refresh loops.

## Documentation

- [LicenseKitLemonSqueezy API reference](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy/documentation/licensekitlemonsqueezy)

The package includes a DocC overview for the public API surface under
`Sources/LicenseKitLemonSqueezy/Documentation.docc`.

## Security

Do not log or commit license keys, activation identifiers, or private response
bodies. This package uses Lemon Squeezy's license-key API and does not require a
store-wide Lemon Squeezy API key. Report vulnerabilities through the process in
[SECURITY.md](SECURITY.md).

## License

LicenseKitLemonSqueezy is available under the MIT License. See [LICENSE](LICENSE).
