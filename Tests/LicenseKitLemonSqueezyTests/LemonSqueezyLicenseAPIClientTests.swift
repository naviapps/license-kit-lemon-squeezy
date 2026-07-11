import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseAPIClientTests: XCTestCase {
  private func makeClient(
    baseURL: URL = URL(string: "https://example.com")!,
    session: LemonSqueezyHTTPSession,
    maximumAttempts: Int = 1
  ) -> LemonSqueezyLicenseAPIClient {
    LemonSqueezyLicenseAPIClient(
      baseURL: baseURL,
      session: session,
      retry: .init(maximumAttempts: maximumAttempts, baseDelay: .milliseconds(1))
    )
  }

  func testActivateReturnsResponseData() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let data = Data("ok".utf8)
    let session = StubHTTPSession(queue: [.success(.init(data: data, response: response))])
    let client = makeClient(session: session)

    let returnedData = try await client.activate(licenseKey: "key", instanceName: "Mac")
    XCTAssertEqual(returnedData, data)
  }

  func testActivateNonHTTPResponseThrowsNetworkFailure() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let response = URLResponse(
      url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    let session = StubHTTPSession(queue: [.success(.init(data: Data(), response: response))])
    let client = makeClient(session: session)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected network error")
    } catch let error as LemonSqueezyLicenseAPIError {
      XCTAssertEqual(error, .networkFailure(message: "Invalid response"))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateNon2xxThrowsMappedAPIError() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let response = try makeHTTPResponse(url: url, statusCode: 400)
    let data = Data(#"{"error":"Bad license key."}"#.utf8)
    let session = StubHTTPSession(queue: [.success(.init(data: data, response: response))])
    let client = makeClient(session: session)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected mapped API error")
    } catch let error as LemonSqueezyLicenseAPIError {
      XCTAssertEqual(error, .requestFailure(message: "Bad license key."))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateInvalidBaseURLThrowsInvalidURL() async {
    let session = StubHTTPSession(queue: [])
    let client = makeClient(baseURL: URL(string: "relative")!, session: session)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected invalid URL error")
    } catch let error as LemonSqueezyLicenseAPIError {
      XCTAssertEqual(error, .invalidURL)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateRejectsNonHTTPSBaseURL() async {
    let session = StubHTTPSession(queue: [])
    let client = makeClient(baseURL: URL(string: "http://example.com")!, session: session)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected invalid URL error")
    } catch let error as LemonSqueezyLicenseAPIError {
      XCTAssertEqual(error, .invalidURL)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateNormalizesBaseURLPathQueryAndFragment() async throws {
    let responseURL = try XCTUnwrap(URL(string: "https://example.com/custom/v1/licenses/activate"))
    let baseURLStrings = [
      "https://example.com/custom",
      "https://example.com/custom/",
      "https://example.com/custom?token=redacted#fragment",
    ]

    for baseURLString in baseURLStrings {
      let response = try makeHTTPResponse(url: responseURL, statusCode: 200)
      let session = StubHTTPSession(
        queue: [.success(.init(data: Data("ok".utf8), response: response))]
      )
      let client = makeClient(
        baseURL: try XCTUnwrap(URL(string: baseURLString)),
        session: session
      )

      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")

      let requests = await session.recordedRequests()
      let request = try XCTUnwrap(requests.first)
      XCTAssertEqual(request.url, responseURL)
    }
  }

  func testActivateIgnoresBaseURLUserInfo() async throws {
    let responseURL = try XCTUnwrap(URL(string: "https://example.com/custom/v1/licenses/activate"))
    let response = try makeHTTPResponse(url: responseURL, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(
      baseURL: try XCTUnwrap(URL(string: "https://user:redacted@example.com/custom")),
      session: session
    )

    _ = try await client.activate(licenseKey: "key", instanceName: "Mac")

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url, responseURL)
    XCTAssertNil(request.url?.user)
    XCTAssertNil(request.url?.password)
  }

  func testActivateRetriesRateLimitResponseThenSucceeds() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let retryResponse = try makeHTTPResponse(
      url: url,
      statusCode: 429,
      headers: ["Retry-After": "0"]
    )
    let successResponse = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(queue: [
      .success(.init(data: Data("retry".utf8), response: retryResponse)),
      .success(.init(data: Data("ok".utf8), response: successResponse)),
    ])
    let client = makeClient(session: session, maximumAttempts: 2)

    let data = try await client.activate(licenseKey: "key", instanceName: "Mac")
    XCTAssertEqual(String(bytes: data, encoding: .utf8), "ok")
  }

  func testActivateDoesNotRetryServerFailure() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let session = StubHTTPSession(queue: [
      .success(
        .init(
          data: Data(),
          response: try makeHTTPResponse(url: url, statusCode: 503)
        )),
      .success(
        .init(
          data: Data("unexpected".utf8),
          response: try makeHTTPResponse(url: url, statusCode: 200)
        )),
    ])
    let client = makeClient(session: session, maximumAttempts: 2)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected server failure")
    } catch let error as LemonSqueezyLicenseAPIError {
      XCTAssertEqual(error, .serverFailure(statusCode: 503))
      let requests = await session.recordedRequests()
      XCTAssertEqual(requests.count, 1)
    }
  }

  func testValidateRetriesServerFailureThenSucceeds() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let session = StubHTTPSession(queue: [
      .success(
        .init(
          data: Data(),
          response: try makeHTTPResponse(url: url, statusCode: 503)
        )),
      .success(
        .init(
          data: Data("ok".utf8),
          response: try makeHTTPResponse(url: url, statusCode: 200)
        )),
    ])
    let client = makeClient(session: session, maximumAttempts: 2)

    let data = try await client.validate(licenseKey: "key", instanceID: nil)

    XCTAssertEqual(String(bytes: data, encoding: .utf8), "ok")
    let requests = await session.recordedRequests()
    XCTAssertEqual(requests.count, 2)
  }

  func testActivateDoesNotRetryTransportError() async throws {
    let session = StubHTTPSession(queue: [
      .failure(URLError(.timedOut))
    ])
    let client = makeClient(session: session, maximumAttempts: 2)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected network error")
    } catch let error as LemonSqueezyLicenseAPIError {
      if case .networkFailure = error {
        let requests = await session.recordedRequests()
        XCTAssertEqual(requests.count, 1)
      } else {
        XCTFail("Expected network error, got \(error)")
      }
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testActivateSendsPOSTAndLicenseAPIHeadersWithoutBearerAuthorization() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(session: session)

    _ = try await client.activate(licenseKey: "key", instanceName: "Mac")

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
  }

  func testActivateSendsDeterministicPercentEncodedBody() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/activate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(session: session)

    _ = try await client.activate(licenseKey: "key/value+plus", instanceName: "Office Mac+Desk")

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Content-Type"),
      "application/x-www-form-urlencoded"
    )
    XCTAssertEqual(
      String(data: try XCTUnwrap(request.httpBody), encoding: .utf8),
      "instance_name=Office%20Mac%2BDesk&license_key=key%2Fvalue%2Bplus"
    )
  }

  func testValidateSendsOptionalInstanceID() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(session: session)

    _ = try await client.validate(licenseKey: "key", instanceID: "instance")

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url, url)
    XCTAssertEqual(
      String(data: try XCTUnwrap(request.httpBody), encoding: .utf8),
      "instance_id=instance&license_key=key"
    )
  }

  func testValidateOmitsMissingInstanceID() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/validate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(session: session)

    _ = try await client.validate(licenseKey: "key", instanceID: nil)

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url, url)
    XCTAssertEqual(
      String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "license_key=key")
  }

  func testDeactivateSendsInstanceID() async throws {
    let url = try XCTUnwrap(URL(string: "https://example.com/v1/licenses/deactivate"))
    let response = try makeHTTPResponse(url: url, statusCode: 200)
    let session = StubHTTPSession(
      queue: [.success(.init(data: Data("ok".utf8), response: response))]
    )
    let client = makeClient(session: session)

    _ = try await client.deactivate(licenseKey: "key", instanceID: "instance")

    let requests = await session.recordedRequests()
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url, url)
    XCTAssertEqual(
      String(data: try XCTUnwrap(request.httpBody), encoding: .utf8),
      "instance_id=instance&license_key=key"
    )
  }

  func testActivatePropagatesCancellation() async throws {
    let session = StubHTTPSession(queue: [
      .failure(CancellationError())
    ])
    let client = makeClient(session: session, maximumAttempts: 2)

    do {
      _ = try await client.activate(licenseKey: "key", instanceName: "Mac")
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      let requests = await session.recordedRequests()
      XCTAssertEqual(requests.count, 1)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
