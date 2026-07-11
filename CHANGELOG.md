# Changelog

All notable user-facing changes to LicenseKitLemonSqueezy will be documented in this file.

Released versions follow semantic versioning.

## [Unreleased]

No changes yet.

## [2.0.0] - 2026-07-12

### Added

- Added `Hashable` conformance to `LemonSqueezyLicenseProvider.LicenseScope`.

### Changed

- Collapsed public configuration into `LemonSqueezyLicenseProvider.Configuration` and
  `LemonSqueezyLicenseProvider.LicenseScope`.
- Renamed `LemonSqueezyLicenseProvider.licenseSource` to `LemonSqueezyLicenseProvider.source`.
- Replaced millisecond retry delay configuration with `Configuration.baseRetryDelay`.
- Raised the minimum deployment targets to iOS 16, tvOS 16, and watchOS 9 to match the public
  `Duration`-based retry configuration and Foundation APIs used by the package.
- Rejected validation and deactivation for activations that were not created by this provider.
- Percent-encoded License API form fields so `+`, `/`, and other reserved characters are preserved.
- Limited automatic retries to retryable HTTP responses instead of retrying transport failures.
- Stripped user-info credentials from configured API base URLs before sending License API requests.
- Added `LICENSE_KIT_PATH` support for testing against a local LicenseKit checkout.
- Raised the required LicenseKit dependency to 2.0.0 and aligned with failable
  `LicenseSource`, `LicenseActivation`, and `LicenseValidationResult` contracts.
- Normalized invalid Lemon Squeezy validation responses so they omit plan and expiration values
  required to be absent by LicenseKit's invalid validation result contract.
- Clarified the LicenseKit dependency in the README requirements.
- Added README links to release notes.
- Clarified that security updates target the latest released version.
- Renamed the activation storage setup sample error to avoid the removed `LicenseStorage` name.
- Updated installation guidance to use the 2.0.0 release line.

### Removed

- Removed top-level `LemonSqueezyLicenseConfiguration` and `LemonSqueezyLicenseScope` because this
  single-provider package no longer needs those names in the public namespace.
- Removed `LemonSqueezyLicenseProvider.Configuration.defaultAPIBaseURL` from the public API because
  the production API URL is an implementation default. Use the explicit `apiBaseURL:` initializer
  only when overriding the endpoint.

## [1.0.0] - 2026-05-17

### Changed

- Declared the first public API release.
- Requires LicenseKit 1.2.0.
- Uses `LicenseActivationRequest` for provider activation.

## [0.1.0] - 2026-05-17

### Added

- Initial public package extraction.
- Added Lemon Squeezy License API activation, validation, and deactivation support for LicenseKit
  1.2.0.
- Focused the public API on `LemonSqueezyLicenseProvider`,
  `LemonSqueezyLicenseConfiguration`, and `LemonSqueezyLicenseScope`.
- Added license scope checks for Lemon Squeezy store, product, and variant IDs.
- Added retry handling for rate limits and server failures, including `Retry-After` support.
- Kept commerce, offerings, pricing, checkout, and customer portal behavior out of this package.
- Added README, DocC and CI metadata for the public package.
