import Foundation

struct LemonSqueezyLicenseAPIResponseParser: Sendable {
  func parseLicenseContext(from data: Data) throws -> LemonSqueezyLicenseContext {
    guard
      let envelope = try? JSONDecoder().decode(
        LemonSqueezyLicenseAPIEnvelope.self,
        from: data
      )
    else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }

    let licenseKeyNode = envelope.licenseKey
    let validValue = envelope.activated ?? envelope.valid

    return try LemonSqueezyLicenseContext(
      licenseKey: licenseKeyNode?.key?.lemonSqueezyTrimmedNonEmpty,
      storeID: envelope.meta?.storeID?.normalizedValue,
      productID: envelope.meta?.productID?.normalizedValue,
      variantID: envelope.meta?.variantID?.normalizedValue,
      activationIdentifier: envelope.instance?.id?.lemonSqueezyTrimmedNonEmpty,
      activationCreatedAt: parseOptionalDate(envelope.instance?.createdAt),
      expiresAt: parseOptionalDate(licenseKeyNode?.expiresAt),
      remainingActivations: remainingActivations(
        licenseKeyNode: licenseKeyNode
      ),
      status: licenseKeyNode?.status?.lemonSqueezyTrimmedNonEmpty,
      isValid: validValue,
      message: envelope.failureMessage
    )
  }

  func parseDeactivationContext(from data: Data) throws -> LemonSqueezyDeactivationContext {
    guard
      let envelope = try? JSONDecoder().decode(
        LemonSqueezyLicenseAPIEnvelope.self,
        from: data
      )
    else {
      throw LemonSqueezyLicenseAPIError.responseParsingFailed
    }
    if let deactivated = envelope.deactivated {
      return LemonSqueezyDeactivationContext(
        succeeded: deactivated,
        message: envelope.failureMessage
      )
    }
    throw LemonSqueezyLicenseAPIError.responseParsingFailed
  }

  private func remainingActivations(
    licenseKeyNode: LemonSqueezyLicenseAPIEnvelope.LicenseKey?
  ) -> Int? {
    guard let activationLimit = nonNegative(licenseKeyNode?.activationLimit) else { return nil }

    let activationUsage: Int
    if let value = licenseKeyNode?.activationUsage {
      guard let nonNegativeValue = nonNegative(value) else { return nil }
      activationUsage = nonNegativeValue
    } else {
      activationUsage = 0
    }
    guard activationUsage < activationLimit else { return 0 }
    return activationLimit - activationUsage
  }

  private func parseOptionalDate(_ string: String?) throws -> Date? {
    guard let string else { return nil }
    let isoWithFractional = ISO8601DateFormatter()
    isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoWithFractional.date(from: string) { return date }

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    if let date = iso.date(from: string) { return date }

    let sqlDateTime = DateFormatter()
    sqlDateTime.locale = Locale(identifier: "en_US_POSIX")
    sqlDateTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
    sqlDateTime.isLenient = false
    sqlDateTime.timeZone = .gmt
    if let date = sqlDateTime.date(from: string) { return date }

    let dateOnly = DateFormatter()
    dateOnly.locale = Locale(identifier: "en_US_POSIX")
    dateOnly.dateFormat = "yyyy-MM-dd"
    dateOnly.isLenient = false
    dateOnly.timeZone = .gmt
    if let date = dateOnly.date(from: string) { return date }

    throw LemonSqueezyLicenseAPIError.responseParsingFailed
  }

  private func nonNegative(_ value: Int?) -> Int? {
    guard let value, value >= 0 else { return nil }
    return value
  }

  // NOTE: DateFormatter / ISO8601DateFormatter instances are not guaranteed to be thread-safe.
  // Keep formatters local to avoid shared mutable state across concurrent calls.
}

struct LemonSqueezyDeactivationContext: Sendable {
  let succeeded: Bool
  let message: String?
}

struct LemonSqueezyLicenseContext: Sendable {
  let licenseKey: String?
  let storeID: String?
  let productID: String?
  let variantID: String?
  let activationIdentifier: String?
  let activationCreatedAt: Date?
  let expiresAt: Date?
  let remainingActivations: Int?
  let status: String?
  let isValid: Bool?
  let message: String?

  var isActivationLimitError: Bool {
    if let message {
      return LemonSqueezyActivationLimitMessage.matches(message)
    }
    return remainingActivations == 0
  }

  var hasNonActiveStatus: Bool {
    guard let status else { return false }
    return status.caseInsensitiveCompare("active") != .orderedSame
  }
}
