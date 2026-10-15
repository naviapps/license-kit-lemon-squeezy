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

Local API catalogs for this checkout:

- [LicenseKitLemonSqueezy](Sources/LicenseKitLemonSqueezy/LicenseKitLemonSqueezy.docc/LicenseKitLemonSqueezy.md)

## Usage

Use `LemonSqueezyLicenseProvider` as the `LicenseProvider` for distributed
Apple apps. LicenseKit owns state, storage, refresh policy, and the public
licensing state your UI reads.

```swift
import LicenseKit
import LicenseKitLemonSqueezy

@MainActor
func makeLicenseManager() -> LicenseManager {
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
  return LicenseManager(
    provider: provider,
    activationStorage: KeychainLicenseActivationStorage(
      service: "com.example.app.license",
      account: "primary"
    )
  )
}
```

From the host's main-actor licensing flow, call
`try await licenseManager.activate(.licenseKey(enteredLicenseKey))` and read
`licenseManager.isLicensed`. The example identifiers are placeholders; provide
scope values from the host's product configuration.

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

Retries are bounded by `Configuration.maximumRequestAttempts`, including the first attempt.
HTTP `429` responses may be retried for activation, validation, and deactivation.
HTTP `5xx` responses are retried only for validation; activation and deactivation do not
retry server errors because the remote operation may already have changed state.
`Retry-After` is honored when valid; otherwise the delay uses exponential backoff.
Transport failures are returned without automatic retry. Use `needsRefresh()` to schedule
routine LicenseKit refreshes instead of a tight polling loop.

Explicit client-error messages saying a license key is expired map to
`LicenseProviderError.invalidLicense`, so LicenseKit removes the rejected
activation instead of granting offline grace. HTTP `429` and `5xx` retain their
recoverable rate-limit/server handling, and unrelated request errors retain
their existing classification.

Recognized activation-limit messages on client-error responses map to
`LicenseProviderError.activationLimitReached`, including HTTP `400`, `409`, and `422`.
HTTP `404` still reports an invalid license; `429` and `5xx` retain their rate-limit
and server-failure handling.

## Repository guide

[Package.swift](Package.swift) defines products, target boundaries, platform requirements,
and dependency resolution.

| Target | Owns | Implementation and tests |
| --- | --- | --- |
| `LicenseKitLemonSqueezy` | License endpoint transport, provider mapping and scope checks | [Source](Sources/LicenseKitLemonSqueezy) · [Tests](Tests/LicenseKitLemonSqueezyTests) |

## Development

```sh
make check
```

The gate runs strict Swift formatting, Debug and Release builds, and the test suite
with complete concurrency checking and warnings as errors. CI runs the same gate.
On macOS, XCTest and DocC validation require full Xcode developer tools. If the
active developer directory is Command Line Tools, set `DEVELOPER_DIR` to the
installed Xcode developer directory for the check command.

For a coordinated local dependency change:

```sh
LICENSE_KIT_PATH=../license-kit make check
```

Without that override, the manifest resolves the GitHub dependency. Verify the
consumer's actual pinned revision separately from a check against local HEAD.

See [AGENTS.md](AGENTS.md) for change guidance and [CONTRIBUTING.md](CONTRIBUTING.md)
for contribution policy. Release history and private reporting stay in
[CHANGELOG.md](CHANGELOG.md) and [SECURITY.md](SECURITY.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in [CHANGELOG.md](CHANGELOG.md).

## Security

Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).

## License

LicenseKitLemonSqueezy is released under the MIT License. See [LICENSE](LICENSE).
