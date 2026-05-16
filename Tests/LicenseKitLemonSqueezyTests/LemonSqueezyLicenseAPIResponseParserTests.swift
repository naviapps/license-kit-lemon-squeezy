import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseAPIResponseParserTests: XCTestCase {
  func testParsesActivationResponse() throws {
    let json = """
      {
        "activated": true,
        "error": null,
        "license_key": {
          "status": "active",
          "key": "ABC-123",
          "activation_limit": 5,
          "activation_usage": 2,
          "expires_at": null
        },
        "instance": {
          "id": "inst_1",
          "name": "Mac",
          "created_at": "2021-04-06T14:15:07.000000Z"
        },
        "meta": {
          "store_id": 123,
          "product_id": 456,
          "variant_id": 1052797,
          "customer_id": 777
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.licenseKey, "ABC-123")
    XCTAssertEqual(context.storeID, "123")
    XCTAssertEqual(context.productID, "456")
    XCTAssertEqual(context.variantID, "1052797")
    XCTAssertEqual(context.status, "active")
    XCTAssertEqual(context.activationID, "inst_1")
    XCTAssertNotNil(context.activationCreatedAt)
    XCTAssertEqual(context.remainingActivations, 3)
    XCTAssertEqual(context.isValid, true)
  }

  func testParsesValidationResponse() throws {
    let json = """
      {
        "valid": true,
        "error": null,
        "license_key": {
          "status": "active",
          "key": "ABC-123",
          "activation_limit": 5,
          "activation_usage": 2,
          "expires_at": "2026-01-01T00:00:00Z"
        },
        "instance": {
          "id": "inst_1"
        },
        "meta": {
          "variant_id": 1052797,
          "customer_id": 777
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.licenseKey, "ABC-123")
    XCTAssertEqual(context.activationID, "inst_1")
    XCTAssertEqual(context.remainingActivations, 3)
    XCTAssertNotNil(context.expiresAt)
    XCTAssertEqual(context.isValid, true)
  }

  func testTrimsStringValues() throws {
    let json = """
      {
        "valid": true,
        "license_key": {
          "status": " active ",
          "key": " ABC-123 ",
          "activation_limit": 5,
          "activation_usage": 2
        },
        "instance": {
          "id": " inst_1 "
        },
        "meta": {
          "store_id": " 123 ",
          "product_id": " 456 ",
          "variant_id": " pro ",
          "customer_id": " cust_1 "
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.licenseKey, "ABC-123")
    XCTAssertEqual(context.storeID, "123")
    XCTAssertEqual(context.productID, "456")
    XCTAssertEqual(context.variantID, "pro")
    XCTAssertEqual(context.status, "active")
    XCTAssertEqual(context.activationID, "inst_1")
    XCTAssertEqual(context.remainingActivations, 3)
    XCTAssertEqual(context.isValid, true)
  }

  func testParsesDocumentedDateFormats() throws {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    let isoContext = try parser.parseLicenseContext(
      from: Data(
        """
        {
          "valid": true,
          "license_key": {
            "expires_at": "2026-01-01T00:00:00.123Z"
          }
        }
        """.utf8
      )
    )
    let sqlDateTimeContext = try parser.parseLicenseContext(
      from: Data(
        """
        {
          "valid": true,
          "license_key": {
            "expires_at": "2026-01-01 00:00:00"
          }
        }
        """.utf8
      )
    )
    let dateOnlyContext = try parser.parseLicenseContext(
      from: Data(
        """
        {
          "valid": true,
          "license_key": {
            "expires_at": "2026-01-01"
          }
        }
        """.utf8
      )
    )

    XCTAssertNotNil(isoContext.expiresAt)
    XCTAssertNotNil(sqlDateTimeContext.expiresAt)
    XCTAssertNotNil(dateOnlyContext.expiresAt)
  }

  func testIgnoresNegativeActivationCounts() throws {
    let json = """
      {
        "license_key": {
          "activation_limit": -1,
          "activation_usage": -10
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertNil(context.remainingActivations)
  }

  func testIgnoresNegativeActivationUsage() throws {
    let json = """
      {
        "license_key": {
          "activation_limit": 5,
          "activation_usage": -2
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.remainingActivations, 5)
  }

  func testParsesTopLevelErrorMessage() throws {
    let json = """
      {
        "activated": false,
        "error": "Activation limit reached",
        "license_key": {
          "key": "ABC-123",
          "status": "active",
          "activation_limit": 5,
          "activation_usage": 5
        },
        "meta": {
          "variant_id": "pro",
          "customer_id": "cust_1"
        }
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.message, "Activation limit reached")
    XCTAssertEqual(context.remainingActivations, 0)
    XCTAssertEqual(context.isValid, false)
  }

  func testParsesFallbackFailureMessage() throws {
    let json = """
      {
        "activated": false,
        "message": "License key is missing"
      }
      """
    let data = try XCTUnwrap(json.data(using: .utf8))
    let parser = LemonSqueezyLicenseAPIResponseParser()
    let context = try parser.parseLicenseContext(from: data)

    XCTAssertEqual(context.message, "License key is missing")
    XCTAssertEqual(context.isValid, false)
  }

  func testThrowsResponseParsingFailureForInvalidPayload() {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    XCTAssertThrowsError(try parser.parseLicenseContext(from: Data("not-json".utf8))) { error in
      XCTAssertEqual(error as? LemonSqueezyLicenseAPIError, .responseParsingFailed)
    }
  }

  func testParsesDeactivationContext() throws {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    XCTAssertTrue(
      try parser.parseDeactivationContext(
        from: Data(#"{ "deactivated": true }"#.utf8)
      ).succeeded
    )
    let failed = try parser.parseDeactivationContext(
      from: Data(#"{ "deactivated": false }"#.utf8)
    )
    XCTAssertFalse(failed.succeeded)
  }

  func testDeactivationRequiresDeactivatedFlag() throws {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    XCTAssertThrowsError(
      try parser.parseDeactivationContext(
        from: Data(#"{ "license_key": { "status": "inactive" } }"#.utf8)
      )
    ) { error in
      XCTAssertEqual(error as? LemonSqueezyLicenseAPIError, .responseParsingFailed)
    }
  }

  func testThrowsResponseParsingFailureForInvalidDeactivationPayload() {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    XCTAssertThrowsError(try parser.parseDeactivationContext(from: Data("not-json".utf8))) {
      error in
      XCTAssertEqual(error as? LemonSqueezyLicenseAPIError, .responseParsingFailed)
    }
  }

  func testParsesDeactivationFailureMessage() throws {
    let parser = LemonSqueezyLicenseAPIResponseParser()

    let context = try parser.parseDeactivationContext(
      from: Data(#"{ "deactivated": false, "error": "License activation was not found." }"#.utf8)
    )

    XCTAssertFalse(context.succeeded)
    XCTAssertEqual(context.message, "License activation was not found.")
  }

  func testActivationLimitHelpers() {
    let context = LemonSqueezyLicenseContext(
      licenseKey: nil,
      storeID: nil,
      productID: nil,
      variantID: nil,
      activationID: nil,
      activationCreatedAt: nil,
      expiresAt: nil,
      remainingActivations: nil,
      status: nil,
      isValid: nil,
      message: "Activation limit reached for this license"
    )

    XCTAssertTrue(context.isActivationLimitError)
    XCTAssertTrue(
      LemonSqueezyActivationLimitMessage.matches("Maximum number of activations exceeded"))
    XCTAssertFalse(LemonSqueezyActivationLimitMessage.matches("Completely different"))
  }
}
