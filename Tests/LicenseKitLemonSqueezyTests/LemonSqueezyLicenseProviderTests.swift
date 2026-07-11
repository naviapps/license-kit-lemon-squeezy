import Foundation
import LicenseKit
import XCTest

@testable import LicenseKitLemonSqueezy

@MainActor
final class LemonSqueezyLicenseProviderTests: XCTestCase {
  func makeProvider(
    session: LemonSqueezyHTTPSession,
    apiBaseURL: URL = URL(string: "https://example.com")!,
    maximumRequestAttempts: Int = 3,
    licenseScope: LemonSqueezyLicenseProvider.LicenseScope = .any
  ) -> LemonSqueezyLicenseProvider {
    let lemonConfig = LemonSqueezyLicenseProvider.Configuration(
      apiBaseURL: apiBaseURL,
      maximumRequestAttempts: maximumRequestAttempts,
      baseRetryDelay: .milliseconds(1),
      licenseScope: licenseScope
    )
    return LemonSqueezyLicenseProvider(configuration: lemonConfig, session: session)
  }

  func makeJSONData(_ json: String) -> Data {
    Data(json.utf8)
  }

  func makeActivation(activationIdentifier: String? = "inst_1") throws -> LicenseActivation {
    try makeLicenseActivation(
      LicenseActivation(
        source: LemonSqueezyLicenseProvider.source,
        planIdentifier: "variant_1",
        activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
        licenseKey: "ABC-123",
        activationIdentifier: activationIdentifier
      ))
  }

  func testActivateReturnsLicenseActivationForActiveLicense() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": true,
        "license_key": {
          "key": "ABC-123",
          "status": "active",
          "activation_limit": 3,
          "activation_usage": 1,
          "expires_at": "2026-12-31T00:00:00Z"
        },
        "instance": {
          "id": "inst_1",
          "created_at": "2021-04-06T14:15:07.000000Z"
        },
        "meta": {
          "customer_id": "cust_1",
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    let activation = try await provider.activate(.licenseKey("ABC-123"))

    XCTAssertEqual(activation.source, LemonSqueezyLicenseProvider.source)
    XCTAssertEqual(activation.licenseKey, "ABC-123")
    XCTAssertEqual(activation.planIdentifier, "variant_1")
    XCTAssertEqual(activation.activationIdentifier, "inst_1")
    XCTAssertEqual(
      ISO8601DateFormatter().string(from: activation.activatedAt),
      "2021-04-06T14:15:07Z"
    )
    XCTAssertNotNil(activation.expiresAt)
  }

  func testActivateRequiresLicenseKey() async throws {
    let session = StubHTTPSession(queue: [])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey(" \n "))
      XCTFail("Expected missing license key")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "Missing license key."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateRejectsAutomaticActivation() async throws {
    let session = StubHTTPSession(queue: [])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.automatic)
      XCTFail("Expected automatic activation rejection")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(
        error,
        .requestFailure(message: "Lemon Squeezy activation requires a license key.")
      )
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateTrimsLicenseKeyAndUsesConfiguredActivationInstanceName() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": true,
        "license_key": {
          "key": "ABC-123",
          "status": "active"
        },
        "instance": {
          "id": "inst_1"
        },
        "meta": {
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let config = LemonSqueezyLicenseProvider.Configuration(
      apiBaseURL: URL(string: "https://example.com")!,
      activationInstanceName: "Example App",
      baseRetryDelay: .milliseconds(1)
    )
    let provider = LemonSqueezyLicenseProvider(configuration: config, session: session)

    let activation = try await provider.activate(.licenseKey(" ABC-123 \n"))

    XCTAssertEqual(activation.licenseKey, "ABC-123")
    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8)
    XCTAssertTrue(body?.contains("license_key=ABC-123") == true)
    XCTAssertTrue(body?.contains("instance_name=Example%20App") == true)
  }

  func testActivateThrowsRequestFailureForInactiveStatus() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": false,
        "error": "License is disabled",
        "license_key": {
          "status": "disabled"
        },
        "meta": {
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected activation failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "License is disabled"))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateTreatsNonActiveStatusAsRequestFailureBeforeActivationLimit() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": false,
        "license_key": {
          "status": "disabled",
          "activation_limit": 1,
          "activation_usage": 1
        },
        "meta": {
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected status rejection")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .requestFailure(message: "Activation failed."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateThrowsActivationLimitReachedWhenValidFlagIsFalseAndNoActivationsRemain()
    async throws
  {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": false,
        "error": "Activation limit reached",
        "license_key": {
          "status": "active",
          "activation_limit": 1,
          "activation_usage": 1
        },
        "meta": {
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected activation limit error")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .activationLimitReached)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateUsesActivationCountsWhenActivationLimitMessageIsMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": false,
        "license_key": {
          "status": "active",
          "activation_limit": 1,
          "activation_usage": 1
        },
        "meta": {
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected activation limit error")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .activationLimitReached)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateThrowsResponseParsingFailureWhenActivationIDMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": true,
        "license_key": {
          "key": "ABC-123",
          "status": "active",
          "activation_limit": 1,
          "activation_usage": 1
        },
        "meta": {
          "customer_id": "cust_1",
          "variant_id": "variant_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected parsing failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .responseDecodingFailure)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateRejectsLicenseFromUnexpectedStoreProductOrVariant() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": true,
        "license_key": {
          "key": "ABC-123",
          "status": "active"
        },
        "instance": {
          "id": "inst_1"
        },
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

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected invalid license")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .invalidLicense)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateThrowsResponseParsingFailureWhenPlanIDMissing() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let payload = makeJSONData(
      """
      {
        "activated": true,
        "license_key": {
          "key": "ABC-123",
          "status": "active",
          "activation_limit": 3,
          "activation_usage": 1
        },
        "meta": {
          "customer_id": "cust_1"
        }
      }
      """)
    let session = StubHTTPSession(queue: [
      .success(.init(data: payload, response: try makeHTTPResponse(url: url, statusCode: 200)))
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected parsing failure")
    } catch let error as LicenseProviderError {
      XCTAssertEqual(error, .responseDecodingFailure)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateWrapsTransportErrorAsTransportFailure() async throws {
    let session = StubHTTPSession(queue: [
      .failure(URLError(.timedOut))
    ])
    let provider = makeProvider(session: session, maximumRequestAttempts: 1)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected network error")
    } catch let error as LicenseProviderError {
      if case let .transportFailure(message) = error {
        XCTAssertEqual(message, URLError(.timedOut).localizedDescription)
      } else {
        XCTFail("Expected network error, got \(error)")
      }
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivatePropagatesCancellation() async throws {
    let session = StubHTTPSession(queue: [
      .failure(CancellationError())
    ])
    let provider = makeProvider(session: session)

    do {
      _ = try await provider.activate(.licenseKey("ABC-123"))
      XCTFail("Expected cancellation")
    } catch is CancellationError {
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
