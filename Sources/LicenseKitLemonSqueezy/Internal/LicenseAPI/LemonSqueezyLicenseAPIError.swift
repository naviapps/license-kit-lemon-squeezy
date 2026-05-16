enum LemonSqueezyLicenseAPIError: Error, Equatable, Sendable {
  case invalidURL
  case networkFailure(message: String)
  case responseParsingFailed
  case invalidLicense
  case activationLimitReached
  case requestFailure(message: String)
  case serverFailure(statusCode: Int)
}

enum LemonSqueezyActivationLimitMessage {
  static func matches(_ message: String) -> Bool {
    let normalized = message.lowercased()
    return normalized.contains("maximum number of activations")
      || normalized.contains("activations remaining")
      || normalized.contains("activation limit")
  }
}
