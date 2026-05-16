# ``LicenseKitLemonSqueezy``

Connect LicenseKit to Lemon Squeezy license activation, validation, and
deactivation.

## Overview

LicenseKitLemonSqueezy is the Lemon Squeezy license-key provider package for
[`LicenseKit`](https://github.com/naviapps/license-kit). It keeps
provider-specific HTTP behavior in this package while LicenseKit owns
provider-neutral license state, storage, refresh, and validation models. It is
intentionally a LicenseKit provider package, not a general Lemon Squeezy SDK.

Use ``LemonSqueezyLicenseProvider`` when your app needs Lemon Squeezy's
license-key endpoints. Activation, validation, and deactivation use the license
key supplied by the customer and do not require a Lemon Squeezy API key.
Deactivation requires the activation identifier returned by Lemon Squeezy when
the license key is activated.

The package intentionally excludes checkout, pricing, offerings, customer
portal, webhooks, and store-wide Lemon Squeezy API access. Keep those flows in
your app, backend, or a separate package.

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

## Configuration

Use ``LemonSqueezyLicenseConfiguration`` for license-key API requests. It
configures the API base URL, retry behavior, and the activation instance name
sent to Lemon Squeezy as `instance_name`. It also carries the accepted Lemon
Squeezy store, product, and variant scope for license keys.

## Using with LicenseKit

Use ``LemonSqueezyLicenseProvider`` as the ``LicenseKit/LicenseProvider`` for
distributed Apple apps. LicenseKit owns state, storage, refresh policy, and the
public licensing state your UI reads.

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

``LicenseKit/LicenseManager`` restores persisted activations from activation
storage during initialization. Restoring from storage does not contact Lemon
Squeezy by itself; call `refresh()` after launch when the restored activation
must be validated before you treat it as current.

```swift
if licenseManager.needsRefresh() {
  try await licenseManager.refresh()
}
```

## License API Example

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

let activation = try await provider.activate(.licenseKey(licenseKey))

let result = try await provider.validate(
  activation,
  validationIdentifier: nil
)

if result.isValid {
  // Continue with licensed app behavior.
}
```

Validation results expose Lemon Squeezy variant IDs as
``LicenseKit/LicenseValidationResult/planID`` when the license API returns them.
Configure ``LemonSqueezyLicenseConfiguration/licenseScope`` to reject license
keys issued for another Lemon Squeezy store, product, or variant. Call
``LemonSqueezyLicenseProvider/deactivate(_:)`` when the activation should be
removed, such as during sign-out or device transfer. Pass a
`validationIdentifier` only when validating a custom activation that does not
already contain Lemon Squeezy's activation identifier.

```swift
try await provider.deactivate(activation)
```

## Rate Limits

Lemon Squeezy rate limits the License API. ``LemonSqueezyLicenseProvider``
retries `429` and server-error responses using `Retry-After` when present and
exponential backoff otherwise. Apps should still avoid tight refresh loops and
let ``LicenseKit/LicenseManager`` and ``LicenseKit/LicenseRefreshPolicy``
control routine validation.

## Security

Treat license keys, activation identifiers, and private response bodies as
sensitive data. This package uses Lemon Squeezy's license-key API and does not
require a store-wide Lemon Squeezy API key.

## Topics

### Providers

- ``LemonSqueezyLicenseProvider``

### Configuration

- ``LemonSqueezyLicenseConfiguration``
- ``LemonSqueezyLicenseScope``
