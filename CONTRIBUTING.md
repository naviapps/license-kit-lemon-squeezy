# Contributing

Thank you for your interest in improving LicenseKitLemonSqueezy.

## Scope

Keep this package focused on Lemon Squeezy's license-key API integration for
LicenseKit:

- Map Lemon Squeezy license activation, validation, and deactivation into
  LicenseKit provider contracts.
- Keep provider-neutral licensing primitives in `license-kit`.
- Keep commerce, offerings, pricing, checkout, and customer portal behavior outside this package.
- Keep app-specific lifecycle, storage policy, and UI outside this package.

Please keep changes focused. Avoid bundling unrelated refactors,
formatting-only rewrites, and behavior changes in the same pull request.

## Development

Run the package checks before opening a pull request:

```sh
just check
```

This runs formatting lint and tests with the same strict Swift settings used by
the package.

If `just` is unavailable, run the underlying commands directly:

```sh
xcrun swift-format lint --strict --recursive --parallel --configuration .swift-format Sources Tests Package.swift
swift test -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

## Pull Requests

Before submitting a pull request:

- Keep the public API surface minimal and documented.
- Add or update tests for behavior changes.
- Update `README.md`, DocC, or `CHANGELOG.md` when user-facing behavior or
  public API changes.
- Do not commit generated build output such as `.build/` or `.swiftpm/`.
- Do not include secrets, tokens, license keys, customer identifiers,
  activation identifiers, private Lemon Squeezy response bodies, local paths, or
  app-specific internal references.

## Security

Do not report vulnerabilities in public issues or pull requests. Follow
[SECURITY.md](SECURITY.md) instead.
