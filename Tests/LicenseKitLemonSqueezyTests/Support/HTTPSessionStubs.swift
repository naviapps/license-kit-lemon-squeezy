import Foundation
import XCTest

@testable import LicenseKitLemonSqueezy

actor StubHTTPSession: LemonSqueezyHTTPSession {
  struct Response {
    let data: Data
    let response: URLResponse
  }

  private var queue: [Result<Response, Error>]
  private var requests: [URLRequest] = []

  init(queue: [Result<Response, Error>]) {
    self.queue = queue
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    requests.append(request)
    guard queue.isEmpty == false else {
      throw URLError(.badServerResponse)
    }
    let next = queue.removeFirst()
    switch next {
    case let .success(response):
      return (response.data, response.response)
    case let .failure(error):
      throw error
    }
  }

  func recordedRequests() -> [URLRequest] {
    requests
  }
}

func makeHTTPResponse(
  url: URL,
  statusCode: Int,
  headers: [String: String] = [:]
) throws -> HTTPURLResponse {
  try XCTUnwrap(
    HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: headers
    )
  )
}
