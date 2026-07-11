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

## Responsibility Boundary

LicenseKitLemonSqueezy owns the LicenseKit provider implementation for Lemon
Squeezy license-key activation, validation, deactivation, provider response
mapping, retry behavior, and license-scope checks.

The package intentionally excludes checkout, pricing, offerings, customer
portal, webhooks, store-wide Lemon Squeezy API access, UI, analytics, and
backend account-management flows. Keep those responsibilities in your app,
backend, or a separate package.

## Configuration

Use ``LemonSqueezyLicenseProvider/Configuration`` for license-key API requests. It
configures the API base URL, retry behavior, and the activation instance name
sent to Lemon Squeezy as `instance_name`. It also carries the accepted Lemon
Squeezy store, product, and variant scope for license keys.

## Usage

Use ``LemonSqueezyLicenseProvider`` as the `LicenseProvider` for
distributed Apple apps. LicenseKit owns state, storage, refresh policy, and the
public licensing state your UI reads.

```swift
import LicenseKit
import LicenseKitLemonSqueezy

let configuration = LemonSqueezyLicenseProvider.Configuration(
  activationInstanceName: "Example App",
  licenseScope: LemonSqueezyLicenseProvider.LicenseScope(
    storeID: "123",
    productID: "456",
    variantIDs: ["789"]
  )
)
let provider = LemonSqueezyLicenseProvider(configuration: configuration)

let licenseKey = "AAAA-BBBB-CCCC"
let activation = try await provider.activate(.licenseKey(licenseKey))

let result = try await provider.validate(
  activation,
  validationIdentifier: nil
)

if result.isValid {
  // Continue with licensed app behavior.
}
```

Configure ``LemonSqueezyLicenseProvider/Configuration/licenseScope`` when a host app must reject
license keys issued for another Lemon Squeezy store, product, or variant. Use
``LemonSqueezyLicenseProvider/deactivate(_:)`` when an activation should be removed, such as during
sign-out or device transfer.

## Rate Limits

Lemon Squeezy rate limits the License API. ``LemonSqueezyLicenseProvider``
retries `429` and server-error responses using `Retry-After` when present and
exponential backoff otherwise. Apps should still avoid tight refresh loops and
let `LicenseManager` and `LicenseRefreshPolicy`
control routine validation. Transport failures are surfaced to the caller
instead of being retried automatically.

## Security

Treat license keys, activation identifiers, and private response bodies as
sensitive data. This package uses Lemon Squeezy's license-key API and does not
require a store-wide Lemon Squeezy API key.

## Topics

### Providers

- ``LemonSqueezyLicenseProvider``
- ``LemonSqueezyLicenseProvider/init(configuration:session:)``
- ``LemonSqueezyLicenseProvider/source``
- ``LemonSqueezyLicenseProvider/activate(_:)``
- ``LemonSqueezyLicenseProvider/validate(_:validationIdentifier:)``
- ``LemonSqueezyLicenseProvider/deactivate(_:)``

### Provider Configuration Types

- ``LemonSqueezyLicenseProvider/Configuration``
- ``LemonSqueezyLicenseProvider/Configuration/init(activationInstanceName:maximumRequestAttempts:baseRetryDelay:licenseScope:)``
- ``LemonSqueezyLicenseProvider/Configuration/init(apiBaseURL:activationInstanceName:maximumRequestAttempts:baseRetryDelay:licenseScope:)``
- ``LemonSqueezyLicenseProvider/Configuration/apiBaseURL``
- ``LemonSqueezyLicenseProvider/Configuration/activationInstanceName``
- ``LemonSqueezyLicenseProvider/Configuration/licenseScope``
- ``LemonSqueezyLicenseProvider/Configuration/maximumRequestAttempts``
- ``LemonSqueezyLicenseProvider/Configuration/baseRetryDelay``
- ``LemonSqueezyLicenseProvider/LicenseScope``
- ``LemonSqueezyLicenseProvider/LicenseScope/any``
- ``LemonSqueezyLicenseProvider/LicenseScope/init(storeID:productID:variantIDs:)``
- ``LemonSqueezyLicenseProvider/LicenseScope/storeID``
- ``LemonSqueezyLicenseProvider/LicenseScope/productID``
- ``LemonSqueezyLicenseProvider/LicenseScope/variantIDs``
