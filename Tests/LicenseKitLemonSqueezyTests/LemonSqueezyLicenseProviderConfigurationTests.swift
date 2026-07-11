import Foundation
import LicenseKitLemonSqueezy
import XCTest

final class LemonSqueezyLicenseProviderConfigurationTests: XCTestCase {
  func testDefaultLicenseConfigurationValues() {
    let config = LemonSqueezyLicenseProvider.Configuration()

    XCTAssertEqual(config.apiBaseURL, URL(string: "https://api.lemonsqueezy.com")!)
    XCTAssertEqual(config.activationInstanceName, "LicenseKit")
    XCTAssertEqual(config.maximumRequestAttempts, 3)
    XCTAssertEqual(config.baseRetryDelay, .milliseconds(200))
    XCTAssertEqual(config.licenseScope, .any)
  }

  func testLicenseConfigurationPreservesBaseURLRetryValuesAndLicenseScope() {
    let config = LemonSqueezyLicenseProvider.Configuration(
      apiBaseURL: URL(string: "https://api.example.com")!,
      activationInstanceName: "  Example App  ",
      maximumRequestAttempts: 2,
      baseRetryDelay: .milliseconds(50),
      licenseScope: LemonSqueezyLicenseProvider.LicenseScope(
        storeID: "123",
        productID: "456",
        variantIDs: ["variant_1", "variant_2"]
      )
    )

    XCTAssertEqual(config.apiBaseURL, URL(string: "https://api.example.com")!)
    XCTAssertEqual(config.activationInstanceName, "Example App")
    XCTAssertEqual(config.maximumRequestAttempts, 2)
    XCTAssertEqual(config.baseRetryDelay, .milliseconds(50))
    XCTAssertEqual(
      config.licenseScope,
      LemonSqueezyLicenseProvider.LicenseScope(
        storeID: "123",
        productID: "456",
        variantIDs: ["variant_1", "variant_2"]
      )
    )
  }

  func testLicenseConfigurationBlankActivationNameFallsBackToDefault() {
    let config = LemonSqueezyLicenseProvider.Configuration(activationInstanceName: "   ")

    XCTAssertEqual(config.activationInstanceName, "LicenseKit")
  }

  func testLicenseConfigurationNormalizesNonPositiveRetryValues() {
    for value in [-1, 0] {
      let config = LemonSqueezyLicenseProvider.Configuration(
        maximumRequestAttempts: value,
        baseRetryDelay: .seconds(value)
      )

      XCTAssertEqual(config.maximumRequestAttempts, 1)
      XCTAssertEqual(config.baseRetryDelay, .milliseconds(1))
    }
  }
}
