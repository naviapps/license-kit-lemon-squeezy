import LicenseKit

extension LicenseProviderError {
  init(_ error: LemonSqueezyLicenseAPIError) {
    switch error {
    case .invalidURL:
      self = .invalidConfiguration
    case let .networkFailure(message: message):
      self = .transportFailure(message: message)
    case .responseParsingFailed:
      self = .responseDecodingFailure
    case .invalidLicense:
      self = .invalidLicense
    case .activationLimitReached:
      self = .activationLimitReached
    case let .requestFailure(message: message):
      self = .requestFailure(message: message)
    case let .serverFailure(statusCode: statusCode):
      self = .serverFailure(statusCode: statusCode)
    }
  }
}
