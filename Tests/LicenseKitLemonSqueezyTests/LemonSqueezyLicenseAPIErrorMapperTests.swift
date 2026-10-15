import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseAPIErrorMapperTests: XCTestCase {
  private let mapper = LemonSqueezyLicenseAPIErrorMapper()

  func testMap404ReturnsInvalidLicense() {
    let limitPayload = Data(#"{"error":"Activation limit reached"}"#.utf8)
    for payload in [nil, limitPayload] {
      let error = mapper.map(statusCode: 404, responseData: payload)
      XCTAssertEqual(error, .invalidLicense)
    }
  }

  func testMapClientErrorActivationLimitMessagesReturnActivationLimitReached() {
    let payloads = [
      Data(#"{"error":"This license key has reached the activation limit."}"#.utf8),
      Data(#"{"errors":[{"detail":"Activation limit reached"}]}"#.utf8),
    ]

    for statusCode in [400, 409, 422] {
      for payload in payloads {
        let error = mapper.map(statusCode: statusCode, responseData: payload)
        XCTAssertEqual(error, .activationLimitReached)
      }
    }
  }

  func testExpiredLicenseClientRejectionIsDefinitive() {
    let payloads = [
      Data(#"{"error":"Your license key is expired."}"#.utf8),
      Data(#"{"errors":[{"detail":"The LICENSE KEY IS EXPIRED."}]}"#.utf8),
    ]
    for statusCode in [400, 409, 422] {
      for payload in payloads {
        XCTAssertEqual(mapper.map(statusCode: statusCode, responseData: payload), .invalidLicense)
      }
    }
  }

  func testExpiredMessageDoesNotOverrideRateLimitOrServerFailure() {
    let payload = Data(#"{"error":"Your license key is expired."}"#.utf8)
    for statusCode in [429, 500, 503] {
      XCTAssertEqual(
        mapper.map(statusCode: statusCode, responseData: payload),
        .serverFailure(statusCode: statusCode)
      )
    }
  }

  func testUnrelatedExpiredRequestIsNotARejectedLicense() {
    let payload = Data(
      #"{"error":"The license request expired before validation completed."}"#.utf8)
    XCTAssertEqual(
      mapper.map(statusCode: 400, responseData: payload),
      .requestFailure(message: "The license request expired before validation completed.")
    )
  }

  func testMap429ReturnsServerFailure() {
    let limitPayload = Data(#"{"error":"Activation limit reached"}"#.utf8)
    for payload in [nil, limitPayload] {
      let error = mapper.map(statusCode: 429, responseData: payload)
      XCTAssertEqual(error, .serverFailure(statusCode: 429))
    }
  }

  func testMap500ReturnsServerFailure() {
    let limitPayload = Data(#"{"error":"Activation limit reached"}"#.utf8)
    for payload in [nil, limitPayload] {
      let error = mapper.map(statusCode: 500, responseData: payload)
      XCTAssertEqual(error, .serverFailure(statusCode: 500))
    }
  }

  func testMap400WithMessageReturnsRequestFailure() {
    let payload = Data(
      """
      {"meta":{"message":"Invalid state"}}
      """.utf8)
    let error = mapper.map(statusCode: 400, responseData: payload)
    if case let .requestFailure(message: message) = error {
      XCTAssertEqual(message, "Invalid state")
    } else {
      XCTFail("Expected requestFailure with message")
    }
  }

  func testMap400WithoutMessageUsesRequestFailureFallback() {
    let error = mapper.map(statusCode: 400, responseData: nil)
    guard case let .requestFailure(message: message) = error else {
      XCTFail("Expected requestFailure fallback")
      return
    }
    XCTAssertFalse(message.isEmpty)
  }

  func testMap400WithInvalidJSONUsesRequestFailureFallback() {
    let error = mapper.map(statusCode: 400, responseData: Data("not-json".utf8))
    guard case let .requestFailure(message: message) = error else {
      XCTFail("Expected requestFailure fallback")
      return
    }
    XCTAssertFalse(message.isEmpty)
  }

  func testMap422WithoutMessageUsesFallback() {
    let error = mapper.map(statusCode: 422, responseData: nil)
    if case let .requestFailure(message: message) = error {
      XCTAssertFalse(message.isEmpty)
    } else {
      XCTFail("Expected requestFailure fallback")
    }
  }

  func testMap401ReturnsRequestFailure() {
    let error = mapper.map(statusCode: 401, responseData: nil)
    guard case .requestFailure = error else {
      XCTFail("Expected requestFailure")
      return
    }
  }

  func testMap422WithNonLimitMessageReturnsRequestFailureMessage() {
    let payload = Data(
      """
      {"errors":[{"detail":"Seat already assigned"}]}
      """.utf8)
    let error = mapper.map(statusCode: 422, responseData: payload)

    XCTAssertEqual(error, .requestFailure(message: "Seat already assigned"))
  }

  func testMapTrimsMessagesAndSkipsBlankErrorEntries() {
    let payload = Data(
      """
      {
        "errors": [
          { "detail": "  ", "message": "\\n" },
          { "detail": " Seat already assigned \\n" }
        ]
      }
      """.utf8)
    let error = mapper.map(statusCode: 422, responseData: payload)

    XCTAssertEqual(error, .requestFailure(message: "Seat already assigned"))
  }

  func testMap409WithMessageReturnsRequestFailure() {
    let payload = Data(
      """
      {"message":"Conflict detected"}
      """.utf8)
    let error = mapper.map(statusCode: 409, responseData: payload)

    XCTAssertEqual(error, .requestFailure(message: "Conflict detected"))
  }

  func testMap400WithTopLevelErrorReturnsRequestFailure() {
    let payload = Data(
      """
      {"error":"License key is missing"}
      """.utf8)
    let error = mapper.map(statusCode: 400, responseData: payload)

    XCTAssertEqual(error, .requestFailure(message: "License key is missing"))
  }

  func testMap400WithJSONAPIErrorTitleReturnsRequestFailure() {
    let payload = Data(
      """
      {"errors":[{"title":"Unauthorized"}]}
      """.utf8)
    let error = mapper.map(statusCode: 400, responseData: payload)

    XCTAssertEqual(error, .requestFailure(message: "Unauthorized"))
  }

  func testMap409WithoutMessageUsesRequestFailureFallback() {
    let error = mapper.map(statusCode: 409, responseData: nil)

    guard case let .requestFailure(message: message) = error else {
      XCTFail("Expected requestFailure fallback")
      return
    }
    XCTAssertFalse(message.isEmpty)
  }

  func testMap503ReturnsServerFailure() {
    let error = mapper.map(statusCode: 503, responseData: nil)
    XCTAssertEqual(error, .serverFailure(statusCode: 503))
  }
}
