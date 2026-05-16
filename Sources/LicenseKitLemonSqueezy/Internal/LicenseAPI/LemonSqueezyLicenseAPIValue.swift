enum LemonSqueezyLicenseAPIValue: Decodable, Equatable, Sendable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
    } else if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let int = try? container.decode(Int.self) {
      self = .int(int)
    } else if let double = try? container.decode(Double.self) {
      self = .double(double)
    } else if let string = try? container.decode(String.self) {
      self = .string(string)
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unsupported License API JSON value."
      )
    }
  }

  var stringValue: String? {
    switch self {
    case let .string(value):
      value.lemonSqueezyTrimmedNonEmpty
    case let .int(value):
      String(value)
    case let .double(value):
      String(value)
    case .bool, .null:
      nil
    }
  }

  var intValue: Int? {
    switch self {
    case let .int(value):
      return value
    case let .double(value):
      guard value.isFinite,
        value >= Double(Int.min),
        value <= Double(Int.max),
        value.rounded(.towardZero) == value
      else { return nil }
      return Int(value)
    case .string, .bool, .null:
      return nil
    }
  }

  var boolValue: Bool? {
    switch self {
    case let .bool(value):
      return value
    case .string, .int, .double, .null:
      return nil
    }
  }
}
