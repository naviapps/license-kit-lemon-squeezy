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

    return LemonSqueezyLicenseContext(
      licenseKey: licenseKeyNode?["key"]?.stringValue,
      storeID: envelope.meta?["store_id"]?.stringValue,
      productID: envelope.meta?["product_id"]?.stringValue,
      variantID: envelope.meta?["variant_id"]?.stringValue,
      activationID: envelope.instance?["id"]?.stringValue,
      activationCreatedAt: parseDate(envelope.instance?["created_at"]?.stringValue),
      expiresAt: parseDate(licenseKeyNode?["expires_at"]?.stringValue),
      remainingActivations: remainingActivations(
        licenseKeyNode: licenseKeyNode
      ),
      status: licenseKeyNode?["status"]?.stringValue,
      isValid: validValue?.boolValue,
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
    if let deactivated = envelope.deactivated?.boolValue {
      return LemonSqueezyDeactivationContext(
        succeeded: deactivated,
        message: envelope.failureMessage
      )
    }
    throw LemonSqueezyLicenseAPIError.responseParsingFailed
  }

  private func remainingActivations(
    licenseKeyNode: [String: LemonSqueezyLicenseAPIValue]?
  ) -> Int? {
    guard let activationLimit = nonNegativeIntValue(licenseKeyNode?["activation_limit"])
    else { return nil }

    let activationUsage =
      nonNegativeIntValue(licenseKeyNode?["activation_usage"]) ?? 0
    guard activationUsage < activationLimit else { return 0 }
    return activationLimit - activationUsage
  }

  private func parseDate(_ string: String?) -> Date? {
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
    sqlDateTime.timeZone = TimeZone(secondsFromGMT: 0)
    if let date = sqlDateTime.date(from: string) { return date }

    let dateOnly = DateFormatter()
    dateOnly.locale = Locale(identifier: "en_US_POSIX")
    dateOnly.dateFormat = "yyyy-MM-dd"
    dateOnly.isLenient = false
    dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
    return dateOnly.date(from: string)
  }

  private func nonNegativeIntValue(_ value: LemonSqueezyLicenseAPIValue?) -> Int? {
    guard let intValue = value?.intValue, intValue >= 0 else { return nil }
    return intValue
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
  let activationID: String?
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
