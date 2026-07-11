import Foundation
import LicenseKit
import XCTest

import LicenseKitLemonSqueezy

@MainActor
extension LemonSqueezyLicenseProviderTests {
  func testDeactivateTrimsLicenseKeyAndActivationID() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/deactivate"))
    let payload = makeJSONData(
      """
      {
        "deactivated": true,
        "error": null
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

    try await provider.deactivate(activation)

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8)
    XCTAssertTrue(body?.contains("license_key=ABC-123") == true)
    XCTAssertTrue(body?.contains("instance_id=inst_1") == true)
  }

  func testDeactivateRequiresActivationID() async throws {
    let session = StubHTTPSession(queue: [])
    let provider = makeProvider(session: session)

    do {
      try await provider.deactivate(makeActivation(activationIdentifier: nil))
      XCTFail("Expected missing activation ID")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "Missing activation ID."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDeactivateRequiresLicenseKey() async throws {
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
      try await provider.deactivate(activation)
      XCTFail("Expected missing license key")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "Missing license key."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDeactivateRejectsNonLemonSqueezyActivationWithoutRequestingAPI() async throws {
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

    do {
      try await provider.deactivate(activation)
      XCTFail("Expected mismatched activation rejection")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(
        error,
        .requestFailure(message: "Activation is not a Lemon Squeezy license activation.")
      )
      let requests = await session.recordedRequests()
      XCTAssertTrue(requests.isEmpty)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDeactivateThrowsRequestFailureWhenResponseIsNotDeactivated() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/deactivate"))
    let payload = makeJSONData(
      """
      {
        "deactivated": false,
        "error": "License activation was not found."
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      try await provider.deactivate(makeActivation(activationIdentifier: "missing"))
      XCTFail("Expected deactivation failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "License activation was not found."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDeactivateThrowsResponseDecodingFailureWhenDeactivatedFlagIsMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/deactivate"))
    let payload = makeJSONData(
      """
      {
        "error": null,
        "license_key": {
          "status": "inactive"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      try await provider.deactivate(makeActivation(activationIdentifier: "inst_1"))
      XCTFail("Expected response decoding failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .responseDecodingFailure)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
