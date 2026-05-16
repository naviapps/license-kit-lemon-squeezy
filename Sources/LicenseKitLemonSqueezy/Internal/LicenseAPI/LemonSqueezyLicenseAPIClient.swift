import Foundation

struct LemonSqueezyLicenseAPIClient: Sendable {
  private let baseURL: URL
  private let transport: LemonSqueezyHTTPTransport
  private let errorMapper = LemonSqueezyLicenseAPIErrorMapper()

  init(
    baseURL: URL,
    session: LemonSqueezyHTTPSession,
    retry: LemonSqueezyRetryPolicy = .init()
  ) {
    self.baseURL = baseURL
    transport = LemonSqueezyHTTPTransport(session: session, retry: retry)
  }

  func activate(licenseKey: String, instanceName: String) async throws -> Data {
    try await postForm(
      path: "/v1/licenses/activate",
      form: [
        "license_key": licenseKey,
        "instance_name": instanceName,
      ])
  }

  func validate(licenseKey: String, instanceID: String?) async throws -> Data {
    var form = [
      "license_key": licenseKey
    ]
    if let instanceID {
      form["instance_id"] = instanceID
    }
    return try await postForm(path: "/v1/licenses/validate", form: form)
  }

  func deactivate(licenseKey: String, instanceID: String) async throws -> Data {
    try await postForm(
      path: "/v1/licenses/deactivate",
      form: [
        "license_key": licenseKey,
        "instance_id": instanceID,
      ])
  }

  private func postForm(path: String, form: [String: String]) async throws -> Data {
    guard let url = makeURL(path: path) else { throw LemonSqueezyLicenseAPIError.invalidURL }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(
      "application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    var bodyComponents = URLComponents()
    bodyComponents.queryItems =
      form
      .sorted { $0.key < $1.key }
      .map { URLQueryItem(name: $0.key, value: $0.value) }
    guard let percentEncoded = bodyComponents.percentEncodedQuery else {
      throw LemonSqueezyLicenseAPIError.invalidURL
    }
    request.httpBody = Data(percentEncoded.utf8)

    do {
      let (data, httpResponse) = try await transport.send(request)
      guard (200...299).contains(httpResponse.statusCode) else {
        throw errorMapper.map(statusCode: httpResponse.statusCode, responseData: data)
      }
      return data
    } catch let error as LemonSqueezyLicenseAPIError {
      throw error
    } catch LemonSqueezyTransportError.invalidResponse {
      throw LemonSqueezyLicenseAPIError.networkFailure(message: "Invalid response")
    } catch {
      if error is CancellationError { throw error }
      throw LemonSqueezyLicenseAPIError.networkFailure(message: Self.networkMessage(for: error))
    }
  }

  private func makeURL(path: String) -> URL? {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
      components.scheme == "https",
      components.host != nil
    else { return nil }
    let normalizedPath = path.hasPrefix("/") ? path : "/" + path
    components.path = appending(normalizedPath, to: baseURL.path)
    components.query = nil
    components.fragment = nil
    return components.url
  }

  private func appending(_ component: String, to path: String) -> String {
    let base = path.hasSuffix("/") ? String(path.dropLast()) : path
    return base + component
  }

  private static func networkMessage(for error: Error) -> String {
    if let urlError = error as? URLError {
      return urlError.localizedDescription
    }
    return String(describing: error)
  }
}
