# AGENTS.md

## Scope and sources of truth

- This repository owns LicenseKitLemonSqueezy. Keep reusable mechanism here and product policy in the host app.
- Read [README.md](README.md) for integration contracts and the repository map.
- `Package.swift` defines products, targets, platform requirements, and dependency resolution. `Makefile` and `.github/workflows` define the checks.
- Read the relevant local API catalog before changing a public contract:
  - [LicenseKitLemonSqueezy](Sources/LicenseKitLemonSqueezy/LicenseKitLemonSqueezy.docc/LicenseKitLemonSqueezy.md)
- Read [SECURITY.md](SECURITY.md) before changing sensitive-data or live-system boundaries.

## Contracts to preserve

- Keep checkout, pricing, webhooks, merchant APIs, and UI outside this provider package.
- Use the nested LemonSqueezyLicenseProvider.Configuration and LicenseScope contracts.
- Preserve bounded HTTP 429 retries for all operations and HTTP 5xx retries for validation only; transport failures are not retried automatically.
- Keep scope validation, source identity checks, and activation identifiers intact; never log license keys or response bodies.

## Change and validation

- Keep README examples and DocC symbols aligned with the implementation. Historical CHANGELOG entries describe released behavior; do not rewrite them to match a newer API.
- Use `make check` before a PR; it covers formatting, Debug/Release builds and strict-concurrency tests.
- Use `LICENSE_KIT_PATH` to test coordinated changes against a local `license-kit` checkout. Verify remote/pinned consumer compatibility separately.
- Use injected providers and fixtures for effects. Report live OS/provider checks separately from deterministic tests.
- Do not hand-edit `.build`, generated projects/DocC output, dependency caches, or local secret files.
