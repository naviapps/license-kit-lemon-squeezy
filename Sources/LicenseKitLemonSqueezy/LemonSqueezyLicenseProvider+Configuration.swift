import Foundation

extension LemonSqueezyLicenseProvider {
  /// Configuration for Lemon Squeezy license-key endpoints.
  public struct Configuration: Equatable, Hashable, Sendable {
    private static let defaultAPIBaseURL: URL = {
      var components = URLComponents()
      components.scheme = "https"
      components.host = "api.lemonsqueezy.com"
      guard let url = components.url else {
        preconditionFailure("The built-in Lemon Squeezy API URL is invalid.")
      }
      return url
    }()

    /// Base URL used for license activation, validation, and deactivation requests.
    public let apiBaseURL: URL
    /// Value sent to Lemon Squeezy as `instance_name` during activation.
    public let activationInstanceName: String
    /// Accepted Lemon Squeezy store, product, and variant scope for license keys.
    public let licenseScope: LicenseScope
    /// Maximum number of total attempts for retryable HTTP responses, including the first attempt.
    public let maximumRequestAttempts: Int
    /// Base HTTP response retry delay before exponential backoff.
    public let baseRetryDelay: Duration

    /// Creates a license-key API configuration for Lemon Squeezy's production API.
    public init(
      activationInstanceName: String = "LicenseKit",
      maximumRequestAttempts: Int = 3,
      baseRetryDelay: Duration = Duration(
        secondsComponent: 0,
        attosecondsComponent: 200_000_000_000_000_000
      ),
      licenseScope: LicenseScope = .any
    ) {
      self.init(
        apiBaseURL: Self.defaultAPIBaseURL,
        activationInstanceName: activationInstanceName,
        maximumRequestAttempts: maximumRequestAttempts,
        baseRetryDelay: baseRetryDelay,
        licenseScope: licenseScope
      )
    }

    /// Creates a license-key API configuration with an explicit API base URL.
    public init(
      apiBaseURL: URL,
      activationInstanceName: String = "LicenseKit",
      maximumRequestAttempts: Int = 3,
      baseRetryDelay: Duration = Duration(
        secondsComponent: 0,
        attosecondsComponent: 200_000_000_000_000_000
      ),
      licenseScope: LicenseScope = .any
    ) {
      self.apiBaseURL = apiBaseURL
      self.activationInstanceName =
        activationInstanceName.lemonSqueezyTrimmedNonEmpty ?? "LicenseKit"
      self.licenseScope = licenseScope
      self.maximumRequestAttempts = max(1, maximumRequestAttempts)
      self.baseRetryDelay =
        baseRetryDelay.lemonSqueezyIsPositive
        ? baseRetryDelay : .lemonSqueezyMinimumRetryDelay
    }
  }
}
