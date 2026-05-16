import Foundation
import LicenseKit

/// LicenseKit provider backed by Lemon Squeezy's license-key API.
public struct LemonSqueezyLicenseProvider: LicenseProvider {
  /// Source identifier used for activations created by Lemon Squeezy.
  public static let licenseSource = LicenseSource(rawValue: "lemon-squeezy")

  private let client: LemonSqueezyLicenseAPIClient
  private let activationInstanceName: String
  private let licenseScope: LemonSqueezyLicenseScope
  private let responseParser = LemonSqueezyLicenseAPIResponseParser()

  /// Creates a license-key API provider.
  public init(
    configuration: LemonSqueezyLicenseConfiguration = .init(), session: URLSession = .shared
  ) {
    self.init(configuration: configuration, session: session as LemonSqueezyHTTPSession)
  }

  init(configuration: LemonSqueezyLicenseConfiguration, session: LemonSqueezyHTTPSession) {
    activationInstanceName = configuration.activationInstanceName
    licenseScope = configuration.licenseScope
    client = LemonSqueezyLicenseAPIClient(
      baseURL: configuration.apiBaseURL,
      session: session,
      retry: LemonSqueezyRetryPolicy(
        maximumAttempts: configuration.maximumRequestAttempts,
        baseDelayMilliseconds: configuration.baseRetryDelayMilliseconds
      )
    )
  }

  // MARK: - Activation

  /// Activates a license key.
  public func activate(
    licenseKey: String
  ) async throws -> LicenseActivation {
    guard let trimmedLicenseKey = licenseKey.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing license key.")
    }
    return try await Self.performProviderRequest {
      return try await performActivationRequest(licenseKey: trimmedLicenseKey)
    }
  }

  private func performActivationRequest(
    licenseKey: String
  ) async throws -> LicenseActivation {
    let data = try await client.activate(
      licenseKey: licenseKey,
      instanceName: activationInstanceName
    )
    let context = try responseParser.parseLicenseContext(from: data)
    return try makeActivation(
      context,
      licenseKey: licenseKey
    )
  }

  private func makeActivation(
    _ context: LemonSqueezyLicenseContext,
    licenseKey: String
  ) throws -> LicenseActivation {
    guard let isActivated = context.isValid else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }

    if context.hasNonActiveStatus {
      throw LemonSqueezyLicenseAPIError.requestFailure(
        message: context.message ?? "Activation failed."
      )
    }

    if isActivated == false {
      throw activationRejectionError(for: context)
    }

    guard licenseScope.contains(context) else {
      throw LemonSqueezyLicenseAPIError.invalidLicense
    }

    guard let variantID = context.variantID, variantID.isEmpty == false else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }
    guard let activationID = context.activationID, activationID.isEmpty == false else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }

    return LicenseActivation(
      source: Self.licenseSource,
      licenseKey: context.licenseKey ?? licenseKey,
      planID: variantID,
      activationID: activationID,
      activatedAt: context.activationCreatedAt ?? Date(),
      expiresAt: context.expiresAt
    )
  }

  private func activationRejectionError(
    for context: LemonSqueezyLicenseContext
  ) -> LemonSqueezyLicenseAPIError {
    if context.isActivationLimitError {
      return .activationLimitReached
    }
    return .requestFailure(message: context.message ?? "Activation failed.")
  }

  // MARK: - Deactivation

  private func performDeactivationRequest(
    licenseKey: String,
    instanceID: String
  ) async throws {
    let data = try await client.deactivate(
      licenseKey: licenseKey,
      instanceID: instanceID
    )

    let context = try responseParser.parseDeactivationContext(from: data)
    guard context.succeeded else {
      throw LemonSqueezyLicenseAPIError.requestFailure(
        message: context.message ?? "Deactivation failed."
      )
    }
  }

  /// Deactivates an existing LicenseKit activation.
  public func deactivate(
    _ activation: LicenseActivation
  ) async throws {
    guard let licenseKey = activation.licenseKey?.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing license key.")
    }
    guard let activationID = activation.activationID?.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing activation ID.")
    }
    try await Self.performProviderRequest {
      try await performDeactivationRequest(
        licenseKey: licenseKey,
        instanceID: activationID
      )
    }
  }

  // MARK: - Validation

  private func performValidationRequest(
    licenseKey: String,
    instanceID: String?
  ) async throws -> LicenseValidationResult {
    let data = try await client.validate(
      licenseKey: licenseKey,
      instanceID: instanceID
    )

    let context = try responseParser.parseLicenseContext(from: data)
    guard let isValid = context.isValid else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }

    if context.hasNonActiveStatus {
      return LicenseValidationResult(isValid: false)
    }

    guard licenseScope.contains(context) else {
      return LicenseValidationResult(isValid: false)
    }

    return LicenseValidationResult(
      isValid: isValid,
      planID: context.variantID,
      expiresAt: context.expiresAt
    )
  }

  /// Validates an existing LicenseKit activation.
  public func validate(
    _ activation: LicenseActivation,
    validationIdentifier: String?
  ) async throws -> LicenseValidationResult {
    guard let licenseKey = activation.licenseKey?.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing license key.")
    }
    let activationID = activation.activationID?.lemonSqueezyTrimmedNonEmpty
    let fallbackInstanceID = validationIdentifier?.lemonSqueezyTrimmedNonEmpty
    return try await Self.performProviderRequest {
      return try await performValidationRequest(
        licenseKey: licenseKey,
        instanceID: activationID ?? fallbackInstanceID
      )
    }
  }

  private static func performProviderRequest<Result>(
    _ operation: () async throws -> Result
  ) async throws -> Result {
    do {
      return try await operation()
    } catch let error as LemonSqueezyLicenseAPIError {
      throw LicenseProviderError(error)
    }
  }

}
