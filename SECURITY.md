# Security Policy

## Supported Versions

Security updates are provided for the latest released version.

## Reporting a Vulnerability

Report security issues through GitHub private vulnerability reporting for this repository.

Do not open a public issue, pull request, or discussion for vulnerabilities, suspected credential
exposure, privacy-sensitive behavior, or issues that could expose private user data.

If private vulnerability reporting is unavailable, open a public issue asking for a private
security contact channel. Do not include vulnerability details, exploit steps, logs, secrets,
tokens, private keys, license keys, activation identifiers, customer identifiers, private Lemon
Squeezy response bodies, personal data, local paths, private app metadata, or app-specific
internal references.

For private reports, include:

- Affected package version or commit
- Affected dependency versions if relevant
- A clear description of the behavior
- Reproduction steps or a minimal proof of concept
- Expected impact
- Affected public API, target, or subsystem

Use placeholders instead of secrets, tokens, private keys, license keys, activation identifiers,
customer identifiers, private Lemon Squeezy response bodies, personal data, local paths, private
app metadata, or app-specific internal references.

We will acknowledge valid reports as soon as practical and coordinate fixes before public
disclosure.

## Scope

Security-sensitive areas include:

- Lemon Squeezy license-key activation, validation, and deactivation
- License keys entered by users
- Activation identifiers
- Customer identifiers and license metadata returned by Lemon Squeezy
- Lemon Squeezy License API response parsing, error mapping, and retry behavior

LicenseKitLemonSqueezy does not require or store a store-wide Lemon Squeezy API key, and it does
not implement commerce, offerings, pricing, checkout, customer portal, app-specific lifecycle,
storage policy, or UI behavior. Host applications are responsible for storing, logging, and
redacting provider data safely.
