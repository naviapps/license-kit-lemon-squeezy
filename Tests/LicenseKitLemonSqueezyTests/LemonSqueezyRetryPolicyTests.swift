import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyRetryPolicyTests: XCTestCase {
  func testNormalizesNonPositiveConfigurationValues() {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 0, baseDelay: .zero)

    XCTAssertEqual(policy.maximumAttempts, 1)
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: nil), 1_000_000)
    XCTAssertFalse(
      policy.shouldRetry(
        statusCode: 500,
        afterAttempt: 1,
        mode: .rateLimitAndServerErrors
      ))
  }

  func testShouldRetryHonorsStatusAndAttempt() {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    XCTAssertTrue(
      policy.shouldRetry(
        statusCode: 500,
        afterAttempt: 1,
        mode: .rateLimitAndServerErrors
      ))
    XCTAssertFalse(
      policy.shouldRetry(statusCode: 500, afterAttempt: 1, mode: .rateLimitOnly)
    )
    XCTAssertTrue(
      policy.shouldRetry(statusCode: 429, afterAttempt: 2, mode: .rateLimitOnly)
    )
    XCTAssertFalse(
      policy.shouldRetry(
        statusCode: 400,
        afterAttempt: 1,
        mode: .rateLimitAndServerErrors
      ))
    XCTAssertFalse(
      policy.shouldRetry(
        statusCode: 503,
        afterAttempt: 3,
        mode: .rateLimitAndServerErrors
      ))
  }

  func testDelayUsesRetryAfterWhenProvided() {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: 0), 0)
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: 2), 2_000_000_000)
  }

  func testDelayUsesExponentialFallback() {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    XCTAssertEqual(
      policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: Int?.none), 200_000_000)
    XCTAssertEqual(
      policy.delayNanoseconds(afterAttempt: 2, retryAfterSeconds: Int?.none), 400_000_000)
    XCTAssertEqual(
      policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: -1), 200_000_000)
  }

  func testDelaySaturatesInsteadOfOverflowing() {
    let policy = LemonSqueezyRetryPolicy(
      maximumAttempts: Int.max,
      baseDelay: .seconds(Int64.max)
    )
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: nil), UInt64.max)
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 128, retryAfterSeconds: nil), UInt64.max)
    XCTAssertEqual(policy.delayNanoseconds(afterAttempt: 1, retryAfterSeconds: Int.max), UInt64.max)
  }

  func testRetryAfterParsesHeader() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    XCTAssertEqual(policy.retryAfterSeconds(from: try makeResponse(retryAfter: "  10  ")), 10)
  }

  func testRetryAfterIgnoresMissingInvalidAndNegativeHeaders() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))

    XCTAssertNil(policy.retryAfterSeconds(from: try makeResponse(retryAfter: nil)))
    XCTAssertNil(policy.retryAfterSeconds(from: try makeResponse(retryAfter: "soon")))
    XCTAssertNil(policy.retryAfterSeconds(from: try makeResponse(retryAfter: "-1")))
  }

  func testRetryAfterParsesHTTPDateHeader() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    let now = Date(timeIntervalSince1970: 1_445_412_420)
    XCTAssertEqual(
      policy.retryAfterSeconds(
        from: try makeResponse(retryAfter: "Wed, 21 Oct 2015 07:28:00 GMT"),
        now: now
      ),
      60
    )
  }

  func testRetryAfterPastHTTPDateClampsToZero() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    let now = Date(timeIntervalSince1970: 1_445_412_480)

    XCTAssertEqual(
      policy.retryAfterSeconds(
        from: try makeResponse(retryAfter: "Wed, 21 Oct 2015 07:28:00 GMT"),
        now: now
      ),
      0
    )
  }

  func testRetryAfterParsesObsoleteHTTPDateHeaders() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    let now = Date(timeIntervalSince1970: 784_111_717)

    let rfc850Response = try makeResponse(retryAfter: "Sunday, 06-Nov-94 08:49:37 GMT")
    XCTAssertEqual(policy.retryAfterSeconds(from: rfc850Response, now: now), 60)

    let asctimeResponse = try makeResponse(retryAfter: "Sun Nov  6 08:49:37 1994")
    XCTAssertEqual(policy.retryAfterSeconds(from: asctimeResponse, now: now), 60)
  }

  func testRetryAfterRFC850YearUsesFiftyYearFutureRule() throws {
    let policy = LemonSqueezyRetryPolicy(maximumAttempts: 3, baseDelay: .milliseconds(200))
    let now = Date(timeIntervalSince1970: 2_524_608_000)
    XCTAssertEqual(
      policy.retryAfterSeconds(
        from: try makeResponse(retryAfter: "Friday, 06-Nov-99 08:49:37 GMT"),
        now: now
      ),
      1_573_030_177
    )
  }

  private func makeResponse(retryAfter: String?) throws -> HTTPURLResponse {
    let headerFields = retryAfter.map { ["Retry-After": $0] }
    return try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(URL(string: "https://example.com")),
        statusCode: 429,
        httpVersion: nil,
        headerFields: headerFields
      )
    )
  }
}
