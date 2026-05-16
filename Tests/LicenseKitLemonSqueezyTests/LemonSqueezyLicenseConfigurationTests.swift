import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseConfigurationTests: XCTestCase {
  func testDefaultLicenseConfigurationValues() {
    let config = LemonSqueezyLicenseConfiguration()

    XCTAssertEqual(
      LemonSqueezyLicenseConfiguration.defaultAPIBaseURL,
      URL(string: "https://api.lemonsqueezy.com")!
    )
    XCTAssertEqual(config.apiBaseURL, LemonSqueezyLicenseConfiguration.defaultAPIBaseURL)
    XCTAssertEqual(config.activationInstanceName, "LicenseKit")
    XCTAssertEqual(config.maximumRequestAttempts, 3)
    XCTAssertEqual(config.baseRetryDelayMilliseconds, 200)
    XCTAssertEqual(config.licenseScope, .any)
  }

  func testLicenseConfigurationPreservesBaseURLRetryValuesAndLicenseScope() {
    let config = LemonSqueezyLicenseConfiguration(
      apiBaseURL: URL(string: "https://api.example.com")!,
      activationInstanceName: "  Example App  ",
      maximumRequestAttempts: 2,
      baseRetryDelayMilliseconds: 50,
      licenseScope: LemonSqueezyLicenseScope(
        storeID: "123",
        productID: "456",
        variantIDs: ["starter", "pro"]
      )
    )

    XCTAssertEqual(config.apiBaseURL, URL(string: "https://api.example.com")!)
    XCTAssertEqual(config.activationInstanceName, "Example App")
    XCTAssertEqual(config.maximumRequestAttempts, 2)
    XCTAssertEqual(config.baseRetryDelayMilliseconds, 50)
    XCTAssertEqual(
      config.licenseScope,
      LemonSqueezyLicenseScope(
        storeID: "123",
        productID: "456",
        variantIDs: ["starter", "pro"]
      )
    )
  }

  func testLicenseConfigurationBlankActivationNameFallsBackToDefault() {
    let config = LemonSqueezyLicenseConfiguration(activationInstanceName: "   ")

    XCTAssertEqual(config.activationInstanceName, "LicenseKit")
  }

  func testLicenseConfigurationNormalizesNonPositiveRetryValues() {
    for value in [-1, 0] {
      let config = LemonSqueezyLicenseConfiguration(
        maximumRequestAttempts: value,
        baseRetryDelayMilliseconds: value
      )

      XCTAssertEqual(config.maximumRequestAttempts, 1)
      XCTAssertEqual(config.baseRetryDelayMilliseconds, 1)
    }
  }
}
