# LicenseKitLemonSqueezy

[![CI](https://github.com/naviapps/license-kit-lemon-squeezy/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/license-kit-lemon-squeezy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Flicense-kit-lemon-squeezy%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy)
[![Supported platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Flicense-kit-lemon-squeezy%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy)

LicenseKitLemonSqueezy is the Lemon Squeezy license-key provider package for
[LicenseKit](https://github.com/naviapps/license-kit). It connects LicenseKit to
Lemon Squeezy license activation, validation, and deactivation without becoming a
general Lemon Squeezy SDK.

## Responsibility Boundary

LicenseKitLemonSqueezy owns Lemon Squeezy license activation, validation, deactivation, retry
policy, and response mapping for LicenseKit providers. It intentionally does not include checkout,
pricing, offerings, customer portal, webhooks, or store-wide Lemon Squeezy API access. Keep those
flows in your app, backend, or a separate package.

## Requirements

- iOS 16, macOS 14, tvOS 16, watchOS 9, visionOS 1, or later
- Swift 6.0 or later
- LicenseKit 2.0.0 or later

## Installation

Add the packages with Swift Package Manager:

```swift
.package(url: "https://github.com/naviapps/license-kit.git", from: "2.0.0"),
.package(url: "https://github.com/naviapps/license-kit-lemon-squeezy.git", from: "2.0.0")
```

Then depend on the products:

```swift
.product(name: "LicenseKit", package: "license-kit"),
.product(name: "LicenseKitLemonSqueezy", package: "license-kit-lemon-squeezy")
```

## Documentation

- [LicenseKitLemonSqueezy API reference](https://swiftpackageindex.com/naviapps/license-kit-lemon-squeezy/documentation/licensekitlemonsqueezy)

## Usage

Use `LemonSqueezyLicenseProvider` as the `LicenseProvider` for distributed
Apple apps. LicenseKit owns state, storage, refresh policy, and the public
licensing state your UI reads.

```swift
import Foundation
import LicenseKit
import LicenseKitLemonSqueezy

struct SecureActivationStorage: LicenseActivationStorage {
  func save(_ activation: LicenseActivation) throws {
    // Store the encoded activation in your app's secure persistence layer.
  }

  func load() throws -> LicenseActivation? {
    nil
  }

  func delete() throws {}
}

let provider = LemonSqueezyLicenseProvider(
  configuration: LemonSqueezyLicenseProvider.Configuration(
    activationInstanceName: "Example App",
    licenseScope: LemonSqueezyLicenseProvider.LicenseScope(
      storeID: "123",
      productID: "456",
      variantIDs: ["789"]
    )
  )
)

let licenseManager = LicenseManager(
  provider: provider,
  activationStorage: SecureActivationStorage()
)

let licenseKey = "AAAA-BBBB-CCCC"
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

Valid validation results expose Lemon Squeezy variant IDs as
`planIdentifier` when the license API returns them. Invalid validation results
omit plan and expiration values to match LicenseKit's provider result contract.
Configure `licenseScope` to reject license keys issued for another Lemon
Squeezy store, product, or variant. Call `LicenseManager.deactivate()` when the
activation should be removed, such as during sign-out or device transfer.
Validation and deactivation only accept activations whose source is
`LemonSqueezyLicenseProvider.source`.

Lemon Squeezy rate limits the License API. The provider retries `429` and
server-error responses with `Retry-After` support and exponential backoff, but
apps should still avoid tight refresh loops. Transport failures are surfaced to
the caller instead of being retried automatically.

## Development

Run the package check with:

```sh
make check
```

GitHub Actions runs the same check on pull requests and pushes to `main`.

The manifest resolves LicenseKit from GitHub by default. Set `LICENSE_KIT_PATH` to test against a
local LicenseKit checkout. GitHub Actions uses this override to validate coordinated changes against
the current LicenseKit repository.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in [CHANGELOG.md](CHANGELOG.md).

## Security

Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).

## License

LicenseKitLemonSqueezy is released under the MIT License. See [LICENSE](LICENSE).
