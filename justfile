default:
    just --list

format:
    xcrun swift-format format --in-place --recursive --parallel --configuration .swift-format Sources Tests Package.swift

lint:
    xcrun swift-format lint --strict --recursive --parallel --configuration .swift-format Sources Tests Package.swift

build:
    swift build

test:
    swift test -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors

check: lint test
