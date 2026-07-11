import Foundation
import LicenseKit

/// LicenseKit provider backed by Lemon Squeezy's license-key API.
public struct LemonSqueezyLicenseProvider: LicenseProvider {
  /// Source identifier used for activations created by Lemon Squeezy.
  public static let source: LicenseSource = {
    guard let source = LicenseSource(identifier: "lemon-squeezy") else {
      preconditionFailure("The built-in Lemon Squeezy license source is invalid.")
    }
    return source
  }()

  private static let mismatchedActivationMessage =
    "Activation is not a Lemon Squeezy license activation."

  private let client: LemonSqueezyLicenseAPIClient
  private let activationInstanceName: String
  private let licenseScope: LicenseScope
  private let responseParser = LemonSqueezyLicenseAPIResponseParser()

  /// Creates a license-key API provider.
  public init(
    configuration: Configuration = .init(), session: URLSession = .shared
  ) {
    self.init(configuration: configuration, session: session as LemonSqueezyHTTPSession)
  }

  init(configuration: Configuration, session: LemonSqueezyHTTPSession) {
    activationInstanceName = configuration.activationInstanceName
    licenseScope = configuration.licenseScope
    client = LemonSqueezyLicenseAPIClient(
      baseURL: configuration.apiBaseURL,
      session: session,
      retry: LemonSqueezyRetryPolicy(
        maximumAttempts: configuration.maximumRequestAttempts,
        baseDelay: configuration.baseRetryDelay
      )
    )
  }

  // MARK: - Activation

  /// Activates a license key.
  public func activate(
    _ request: LicenseActivationRequest
  ) async throws -> LicenseActivation {
    let licenseKey: String
    switch request {
    case .automatic:
      throw LicenseProviderError.requestFailure(
        message: "Lemon Squeezy activation requires a license key."
      )
    case .licenseKey(let requestedLicenseKey):
      licenseKey = requestedLicenseKey
    }

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
    guard let activationIdentifier = context.activationIdentifier,
      activationIdentifier.isEmpty == false
    else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }

    return try Self.requireActivation(
      LicenseActivation(
        source: Self.source,
        planIdentifier: variantID,
        activatedAt: context.activationCreatedAt ?? Date(),
        licenseKey: context.licenseKey ?? licenseKey,
        activationIdentifier: activationIdentifier,
        expiresAt: context.expiresAt
      )
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

  private static func requireActivation(_ activation: LicenseActivation?) throws
    -> LicenseActivation
  {
    guard let activation else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }
    return activation
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
    guard Self.isLemonSqueezyActivation(activation) else {
      throw LicenseProviderError.requestFailure(message: Self.mismatchedActivationMessage)
    }
    guard let licenseKey = activation.licenseKey?.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing license key.")
    }
    guard let activationIdentifier = activation.activationIdentifier?.lemonSqueezyTrimmedNonEmpty
    else {
      throw LicenseProviderError.requestFailure(message: "Missing activation ID.")
    }
    try await Self.performProviderRequest {
      try await performDeactivationRequest(
        licenseKey: licenseKey,
        instanceID: activationIdentifier
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

    guard isValid else {
      return try Self.requireValidationResult(LicenseValidationResult(isValid: false))
    }

    if context.hasNonActiveStatus {
      return try Self.requireValidationResult(LicenseValidationResult(isValid: false))
    }

    guard licenseScope.contains(context) else {
      return try Self.requireValidationResult(LicenseValidationResult(isValid: false))
    }

    return try Self.requireValidationResult(
      LicenseValidationResult(
        isValid: isValid,
        planIdentifier: context.variantID,
        expiresAt: context.expiresAt
      )
    )
  }

  /// Validates an existing LicenseKit activation.
  public func validate(
    _ activation: LicenseActivation,
    validationIdentifier: String?
  ) async throws -> LicenseValidationResult {
    guard Self.isLemonSqueezyActivation(activation) else {
      return try Self.requireValidationResult(LicenseValidationResult(isValid: false))
    }
    guard let licenseKey = activation.licenseKey?.lemonSqueezyTrimmedNonEmpty else {
      throw LicenseProviderError.requestFailure(message: "Missing license key.")
    }
    let activationIdentifier = activation.activationIdentifier?.lemonSqueezyTrimmedNonEmpty
    let fallbackInstanceID = validationIdentifier?.lemonSqueezyTrimmedNonEmpty
    return try await Self.performProviderRequest {
      return try await performValidationRequest(
        licenseKey: licenseKey,
        instanceID: activationIdentifier ?? fallbackInstanceID
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

  private static func requireValidationResult(_ result: LicenseValidationResult?) throws
    -> LicenseValidationResult
  {
    guard let result else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }
    return result
  }

  private static func isLemonSqueezyActivation(_ activation: LicenseActivation) -> Bool {
    activation.source == Self.source
  }
}
