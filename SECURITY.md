# Security Policy

## Supported Versions

Security updates are provided for the latest released version.

## Reporting a Vulnerability

Please report vulnerabilities privately through GitHub's private vulnerability
reporting for this repository when available. If that is unavailable, contact
the maintainer privately before publishing details. If no private channel is
available, open a public issue requesting a private contact channel without
including vulnerability details.

Do not include secrets, tokens, license keys, personal data, customer
identifiers, activation identifiers, private Lemon Squeezy response bodies, or
private logs in public issues.

## Sensitive Data

This package can process:

- License keys entered by users
- Activation identifiers
- Customer identifiers returned by Lemon Squeezy
- Lemon Squeezy License API response bodies

Callers are responsible for storing and logging those values safely.

## Package Scope

This package only implements the Lemon Squeezy license-key provider for
LicenseKit activation, validation, and deactivation. It does not require or store
a store-wide Lemon Squeezy API key, and it does not implement commerce,
offerings, pricing, checkout, customer portal, app-specific lifecycle, storage
policy, or UI behavior.
