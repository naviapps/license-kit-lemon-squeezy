import LicenseKit
import XCTest

func makeLicenseActivation(_ activation: LicenseActivation?) throws -> LicenseActivation {
  try XCTUnwrap(activation)
}

func makeLicenseSource(_ identifier: String) throws -> LicenseSource {
  try XCTUnwrap(LicenseSource(identifier: identifier))
}
