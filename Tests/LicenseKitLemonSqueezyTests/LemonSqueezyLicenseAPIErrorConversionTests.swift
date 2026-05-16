import LicenseKit
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseAPIErrorConversionTests: XCTestCase {
  func testConvertsEveryAPIErrorToLicenseProviderError() {
    let cases: [(LemonSqueezyLicenseAPIError, LicenseProviderError)] = [
      (.invalidURL, .invalidConfiguration),
      (.networkFailure(message: "offline"), .transportFailure(message: "offline")),
      (.responseParsingFailed, .responseDecodingFailure),
      (.invalidLicense, .invalidLicense),
      (.activationLimitReached, .activationLimitReached),
      (.requestFailure(message: "bad request"), .requestFailure(message: "bad request")),
      (.serverFailure(statusCode: 429), .serverFailure(statusCode: 429)),
      (.serverFailure(statusCode: 503), .serverFailure(statusCode: 503)),
    ]

    for (apiError, providerError) in cases {
      XCTAssertEqual(LicenseProviderError(apiError), providerError)
    }
  }
}
