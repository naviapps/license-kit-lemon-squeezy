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

    if statusCode == 422 {
      if let message,
        LemonSqueezyActivationLimitMessage.matches(message)
      {
        return .activationLimitReached
      }
      if let message {
        return .requestFailure(message: message)
      }
    }

    if (500...599).contains(statusCode) {
      return .serverFailure(statusCode: statusCode)
    }

    if (400...499).contains(statusCode) {
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
