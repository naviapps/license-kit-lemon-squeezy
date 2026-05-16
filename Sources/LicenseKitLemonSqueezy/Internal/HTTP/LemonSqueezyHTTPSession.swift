import Foundation

protocol LemonSqueezyHTTPSession: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: LemonSqueezyHTTPSession {}
