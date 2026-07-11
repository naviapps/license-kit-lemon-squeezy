import Foundation
import LicenseKit
import XCTest

import LicenseKitLemonSqueezy

@MainActor
extension LemonSqueezyLicenseProviderTests {
  func testValidateUsesStoredActivationIDAndReturnsFalseWhenExplicitlyInvalid() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": false,
        "license_key": {
          "activation_limit": 1,
          "activation_usage": 1
        },
        "meta": {
          "customer_id": "cust_2"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let activation = try makeLicenseActivation(
      LicenseActivation(
        source: LemonSqueezyLicenseProvider.source,
        planIdentifier: "variant_1",
        activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
        licenseKey: " ABC-123 \n",
        activationIdentifier: " inst_1 \n"
      ))
    let response = try await provider.validate(activation, validationIdentifier: "fallback")

    XCTAssertFalse(response.isValid)
    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8)
    XCTAssertTrue(body?.contains("license_key=ABC-123") == true)
    XCTAssertTrue(body?.contains("instance_id=inst_1") == true)
    XCTAssertFalse(body?.contains("fallback") == true)
  }

  func testValidateDropsPlanAndExpirationWhenExplicitlyInvalid() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": false,
        "license_key": {
          "expires_at": "2026-12-31T00:00:00Z"
        },
        "meta": {
          "variant_id": "variant_2"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let response = try await provider.validate(
      makeActivation(activationIdentifier: "inst_1"),
      validationIdentifier: nil
    )

    XCTAssertFalse(response.isValid)
    XCTAssertNil(response.planIdentifier)
    XCTAssertNil(response.expiresAt)
  }

  func testValidateRequiresLicenseKey() async throws {
    let session = StubHTTPSession(queue: [])
    let provider = makeProvider(session: session)

    let activation = try makeLicenseActivation(
      LicenseActivation(
        source: LemonSqueezyLicenseProvider.source,
        planIdentifier: "variant_1",
        activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
        licenseKey: " \n ",
        activationIdentifier: "inst_1"
      ))

    do {
      _ = try await provider.validate(activation, validationIdentifier: "inst_1")
      XCTFail("Expected missing license key")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "Missing license key."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testValidateReturnsFalseForNonLemonSqueezyActivationWithoutRequestingAPI() async throws {
    let session = StubHTTPSession(queue: [])
    let provider = makeProvider(session: session)
    let activation = try makeLicenseActivation(
      LicenseActivation(
        source: try makeLicenseSource("other"),
        planIdentifier: "variant_1",
        activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
        licenseKey: "ABC-123",
        activationIdentifier: "inst_1"
      ))

    let response = try await provider.validate(activation, validationIdentifier: nil)

    XCTAssertFalse(response.isValid)
    XCTAssertNil(response.planIdentifier)
    let requests = await session.recordedRequests()
    XCTAssertTrue(requests.isEmpty)
  }

  func testValidateReturnsTrueWhenExplicitlyValid() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": true,
        "license_key": {
          "expires_at": "2026-12-31T00:00:00Z"
        },
        "meta": {
          "customer_id": "cust_3",
          "variant_id": "variant_2"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let response = try await provider.validate(
      makeActivation(activationIdentifier: nil),
      validationIdentifier: nil
    )

    XCTAssertTrue(response.isValid)
    XCTAssertEqual(response.planIdentifier, "variant_2")
    XCTAssertNotNil(response.expiresAt)
    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(
      String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "license_key=ABC-123")
  }

  func testValidateReturnsFalseForUnexpectedStoreProductOrVariant() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": true,
        "meta": {
          "store_id": "123",
          "product_id": "456",
          "variant_id": "variant_2"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(
      session: session,
      licenseScope: LemonSqueezyLicenseProvider.LicenseScope(
        storeID: "123",
        productID: "456",
        variantIDs: ["variant_1"]
      )
    )

    let response = try await provider.validate(
      makeActivation(activationIdentifier: nil),
      validationIdentifier: nil
    )

    XCTAssertFalse(response.isValid)
    XCTAssertNil(response.planIdentifier)
  }

  func testValidateReturnsFalseForNonActiveLicenseStatus() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": true,
        "license_key": {
          "status": "disabled"
        },
        "meta": {
          "variant_id": "variant_2"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let response = try await provider.validate(
      makeActivation(activationIdentifier: "inst_1"),
      validationIdentifier: nil
    )

    XCTAssertFalse(response.isValid)
    XCTAssertNil(response.planIdentifier)
  }

  func testValidateUsesValidationIdentifierWhenActivationIDIsMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "valid": true,
        "meta": {
          "customer_id": "cust_5"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let response = try await provider.validate(
      makeActivation(activationIdentifier: nil),
      validationIdentifier: " inst_from_protocol \n"
    )

    XCTAssertTrue(response.isValid)
    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8)
    XCTAssertTrue(body?.contains("license_key=ABC-123") == true)
    XCTAssertTrue(body?.contains("instance_id=inst_from_protocol") == true)
  }

  func testValidateThrowsResponseParsingFailureWhenValidFlagMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let payload = makeJSONData(
      """
      {
        "license_key": {
          "status": "active"
        },
        "meta": {
          "customer_id": "cust_4"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.validate(
        makeActivation(activationIdentifier: nil),
        validationIdentifier: nil
      )
      XCTFail("Expected parsing failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .responseDecodingFailure)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
