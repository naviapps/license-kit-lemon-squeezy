import Foundation

struct LemonSqueezyLicenseAPIErrorMapper: Sendable {
  private static let fallbackRequestFailureMessage =
    "Lemon Squeezy license API request failed."

  func map(statusCode: Int, responseData: Data?) -> LemonSqueezyLicenseAPIError {
    let message = Self.extractErrorMessage(from: responseData)

    if statusCode == 404 {
      return .invalidLicense
    }

    if statusCode == 429 {
      return .serverFailure(statusCode: statusCode)
    }

    if (500...599).contains(statusCode) {
      return .serverFailure(statusCode: statusCode)
    }

    if (400...499).contains(statusCode) {
      // An explicit expiry rejection is authoritative, not an offline failure.
      if let message, message.lowercased().contains("license key is expired") {
        return .invalidLicense
      }
      if let message, LemonSqueezyActivationLimitMessage.matches(message) {
        return .activationLimitReached
      }
      return .requestFailure(message: message ?? Self.fallbackRequestFailureMessage)
    }

    if let message {
      return .requestFailure(message: message)
    }

    return .serverFailure(statusCode: statusCode)
  }

  private static func extractErrorMessage(from data: Data?) -> String? {
    guard let data,
      let envelope = try? JSONDecoder().decode(LemonSqueezyLicenseAPIEnvelope.self, from: data)
    else {
      return nil
    }

    return envelope.failureMessage
  }
}
