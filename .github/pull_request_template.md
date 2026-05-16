## Summary


## Related Issue


## Changes


## Impact and Scope

- [ ] Public API changes are intentional and documented, if any
- [ ] Provider-neutral licensing logic remains in `license-kit`
- [ ] App lifecycle, storage policy, UI, and commerce behavior remain outside this package
- [ ] Lemon Squeezy license-key behavior stays scoped to activation, validation, and deactivation

## Validation

- [ ] `xcrun swift-format lint --strict --recursive --parallel --configuration .swift-format Sources Tests Package.swift`
- [ ] `swift test -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors`
- [ ] Documentation updated or not needed
- [ ] `CHANGELOG.md` updated or not needed
- [ ] No generated build output committed
- [ ] No secrets, tokens, license keys, or personal data included
- [ ] No customer identifiers or activation identifiers included
- [ ] No private Lemon Squeezy response bodies, local paths, or app-internal references included

If any validation was not run, explain why.

## Notes
