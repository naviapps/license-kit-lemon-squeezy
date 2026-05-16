# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-05-17

- First stable public release.
- Requires LicenseKit 1.2.0.
- Uses `LicenseActivationRequest` for provider activation.

## [0.1.0] - 2026-05-16

- Initial public package extraction.
- Added Lemon Squeezy License API activation, validation, and deactivation
  support for LicenseKit 1.2.0.
- Focused the public API on `LemonSqueezyLicenseProvider`,
  `LemonSqueezyLicenseConfiguration`, and `LemonSqueezyLicenseScope`.
- Added license scope checks for Lemon Squeezy store, product, and variant IDs.
- Added retry handling for rate limits and server failures, including
  `Retry-After` support.
- Kept commerce, offerings, pricing, checkout, and customer portal behavior out
  of this package.
- Added README, DocC, Swift Package Index, and CI metadata for the public
  package.
