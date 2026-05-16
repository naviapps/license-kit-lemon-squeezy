struct LemonSqueezyLicenseAPIEnvelope: Decodable, Sendable {
  let activated: LemonSqueezyLicenseAPIValue?
  let deactivated: LemonSqueezyLicenseAPIValue?
  let valid: LemonSqueezyLicenseAPIValue?
  let error: LemonSqueezyLicenseAPIValue?
  let licenseKey: [String: LemonSqueezyLicenseAPIValue]?
  let instance: [String: LemonSqueezyLicenseAPIValue]?
  let meta: [String: LemonSqueezyLicenseAPIValue]?
  let errors: [LemonSqueezyLicenseAPIErrorNode]?
  let message: String?

  enum CodingKeys: String, CodingKey {
    case activated
    case deactivated
    case valid
    case error
    case licenseKey = "license_key"
    case instance
    case meta
    case errors
    case message
  }
}

struct LemonSqueezyLicenseAPIErrorNode: Decodable, Sendable {
  let detail: String?
  let message: String?
  let title: String?
}

extension LemonSqueezyLicenseAPIEnvelope {
  var failureMessage: String? {
    if let errors {
      for error in errors {
        if let detail = error.detail?.lemonSqueezyTrimmedNonEmpty { return detail }
        if let message = error.message?.lemonSqueezyTrimmedNonEmpty { return message }
        if let title = error.title?.lemonSqueezyTrimmedNonEmpty { return title }
      }
    }

    if let meta {
      if let message = meta["message"]?.stringValue { return message }
      if let error = meta["error"]?.stringValue { return error }
    }

    if let error = error?.stringValue { return error }
    if let message = message?.lemonSqueezyTrimmedNonEmpty { return message }

    return nil
  }
}
