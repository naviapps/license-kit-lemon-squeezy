struct LemonSqueezyLicenseAPIEnvelope: Decodable, Sendable {
  let activated: Bool?
  let deactivated: Bool?
  let valid: Bool?
  let error: String?
  let licenseKey: LicenseKey?
  let instance: Instance?
  let meta: Metadata?
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

  struct LicenseKey: Decodable, Sendable {
    let status: String?
    let key: String?
    let activationLimit: Int?
    let activationUsage: Int?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
      case status
      case key
      case activationLimit = "activation_limit"
      case activationUsage = "activation_usage"
      case expiresAt = "expires_at"
    }
  }

  struct Instance: Decodable, Sendable {
    let id: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
      case id
      case createdAt = "created_at"
    }
  }

  struct Metadata: Decodable, Sendable {
    let storeID: Identifier?
    let productID: Identifier?
    let variantID: Identifier?
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
      case storeID = "store_id"
      case productID = "product_id"
      case variantID = "variant_id"
      case message
      case error
    }
  }

  enum Identifier: Decodable, Sendable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let value = try? container.decode(Int.self) {
        guard value > 0 else {
          throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Lemon Squeezy identifiers must be positive."
          )
        }
        self = .integer(value)
      } else {
        let value = try container.decode(String.self)
        guard value.lemonSqueezyTrimmedNonEmpty != nil else {
          throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Lemon Squeezy identifiers must not be empty."
          )
        }
        self = .string(value)
      }
    }

    var normalizedValue: String? {
      switch self {
      case .integer(let value):
        String(value)
      case .string(let value):
        value.lemonSqueezyTrimmedNonEmpty
      }
    }
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

    if let message = meta?.message?.lemonSqueezyTrimmedNonEmpty { return message }
    if let error = meta?.error?.lemonSqueezyTrimmedNonEmpty { return error }

    if let error = error?.lemonSqueezyTrimmedNonEmpty { return error }
    if let message = message?.lemonSqueezyTrimmedNonEmpty { return message }

    return nil
  }
}
