import Foundation

enum LemonSqueezyTransportError: Error, Equatable, Sendable {
  case invalidResponse
}

struct LemonSqueezyHTTPTransport: Sendable {
  private let session: LemonSqueezyHTTPSession
  private let retry: LemonSqueezyRetryPolicy

  init(session: LemonSqueezyHTTPSession, retry: LemonSqueezyRetryPolicy) {
    self.session = session
    self.retry = retry
  }

  func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    for attempt in 1...retry.maximumAttempts {
      do {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
          throw LemonSqueezyTransportError.invalidResponse
        }

        if retry.shouldRetry(statusCode: http.statusCode, afterAttempt: attempt) {
          let retryAfter = retry.retryAfterSeconds(from: http)
          try await Task.sleep(
            nanoseconds: retry.delayNanoseconds(
              afterAttempt: attempt, retryAfterSeconds: retryAfter))
          continue
        }

        return (data, http)
      } catch LemonSqueezyTransportError.invalidResponse {
        throw LemonSqueezyTransportError.invalidResponse
      } catch {
        if error is CancellationError { throw error }
        if attempt < retry.maximumAttempts {
          try await Task.sleep(
            nanoseconds: retry.delayNanoseconds(afterAttempt: attempt, retryAfterSeconds: nil))
          continue
        }
        throw error
      }
    }

    throw LemonSqueezyTransportError.invalidResponse
  }
}
