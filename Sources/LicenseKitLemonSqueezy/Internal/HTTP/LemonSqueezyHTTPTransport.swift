import Foundation

enum LemonSqueezyTransportError: Error, Equatable, Sendable {
  case invalidResponse
}

enum LemonSqueezyHTTPRetryMode: Sendable {
  case rateLimitOnly
  case rateLimitAndServerErrors
}

struct LemonSqueezyHTTPTransport: Sendable {
  private let session: LemonSqueezyHTTPSession
  private let retry: LemonSqueezyRetryPolicy

  init(session: LemonSqueezyHTTPSession, retry: LemonSqueezyRetryPolicy) {
    self.session = session
    self.retry = retry
  }

  func send(
    _ request: URLRequest,
    retryMode: LemonSqueezyHTTPRetryMode
  ) async throws -> (Data, HTTPURLResponse) {
    for attempt in 1...retry.maximumAttempts {
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw LemonSqueezyTransportError.invalidResponse
      }

      if retry.shouldRetry(
        statusCode: httpResponse.statusCode,
        afterAttempt: attempt,
        mode: retryMode
      ) {
        let retryAfter = retry.retryAfterSeconds(from: httpResponse)
        try await Task.sleep(
          nanoseconds: retry.delayNanoseconds(
            afterAttempt: attempt, retryAfterSeconds: retryAfter))
        continue
      }

      return (data, httpResponse)
    }

    throw LemonSqueezyTransportError.invalidResponse
  }
}
