import Foundation

/// Configuration for Lemon Squeezy license-key endpoints.
public struct LemonSqueezyLicenseConfiguration: Sendable {
  /// Default Lemon Squeezy license API base URL.
  public static let defaultAPIBaseURL = URL(string: "https://api.lemonsqueezy.com")!

  /// Base URL used for license activation, validation, and deactivation requests.
  public let apiBaseURL: URL
  /// Value sent to Lemon Squeezy as `instance_name` during activation.
  public let activationInstanceName: String
  /// Maximum number of total request attempts, including the first attempt.
  public let maximumRequestAttempts: Int
  /// Base retry delay in milliseconds before exponential backoff.
  public let baseRetryDelayMilliseconds: Int
  /// Accepted Lemon Squeezy store, product, and variant scope for license keys.
  public let licenseScope: LemonSqueezyLicenseScope

  /// Creates a license-key API configuration.
  public init(
    apiBaseURL: URL = Self.defaultAPIBaseURL,
    activationInstanceName: String = "LicenseKit",
    maximumRequestAttempts: Int = 3,
    baseRetryDelayMilliseconds: Int = 200,
    licenseScope: LemonSqueezyLicenseScope = .any
  ) {
    self.apiBaseURL = apiBaseURL
    self.activationInstanceName =
      activationInstanceName.lemonSqueezyTrimmedNonEmpty ?? "LicenseKit"
    self.maximumRequestAttempts = max(1, maximumRequestAttempts)
    self.baseRetryDelayMilliseconds = max(1, baseRetryDelayMilliseconds)
    self.licenseScope = licenseScope
  }
}
