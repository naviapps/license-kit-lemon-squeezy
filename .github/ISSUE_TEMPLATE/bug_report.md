---
name: Bug report
about: Report a reproducible LicenseKitLemonSqueezy issue
title: ""
labels: bug
assignees: ""
---

## Summary

Describe the issue in one or two sentences.

Do not include vulnerability details, secrets, tokens, license keys, personal
data, customer identifiers, activation identifiers, private Lemon Squeezy
response bodies, or private logs in public issues. Follow `SECURITY.md` for
security reports.

## Environment

- LicenseKitLemonSqueezy version or commit:
- LicenseKit version or commit:
- Installation method: Swift Package Manager / other
- Apple platform and OS version:
- Swift version:
- Affected operation: activate / validate / deactivate
- Network condition: online / offline / intermittent / rate limited
- Reproducibility: always / sometimes / once

## Reproduction

Provide the smallest code sample or test case that reproduces the issue. Use
placeholders instead of real license keys, activation identifiers, customer
identifiers, or private Lemon Squeezy response bodies.

1.
2.
3.

## Provider Scope

- Does the corresponding Lemon Squeezy license key record look active and valid?
- Does the issue reproduce when calling `LemonSqueezyLicenseProvider` directly?
- Does the issue depend on license scope, a custom API base URL, LicenseKit
  storage, refresh policy, or app UI state?

## Expected Behavior


## Actual Behavior

Include the exact error, thrown error type, failing assertion, or relevant public
API result. Redact any sensitive values.

If this is an HTTP or retry issue, include only safe metadata:

- HTTP status code:
- `Retry-After` header value, if present:
- Number of observed attempts:
- Whether the final error was `serverFailure`, `transportFailure`, or another public error:

## Additional Context
