import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseAPIValueTests: XCTestCase {
  func testStringValueConversion() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("\"hello\"".utf8)
    )
    XCTAssertEqual(value.stringValue, "hello")
  }

  func testStringValueTrimsAndRejectsBlankStrings() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("\"  hello  \\n\"".utf8)
    )
    let blank = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("\"  \\n\"".utf8)
    )

    XCTAssertEqual(value.stringValue, "hello")
    XCTAssertNil(blank.stringValue)
  }

  func testIntValueConversion() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("123".utf8)
    )
    XCTAssertEqual(value.intValue, 123)
    XCTAssertEqual(value.stringValue, "123")
  }

  func testBoolValueConversion() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("true".utf8)
    )
    XCTAssertEqual(value.boolValue, true)
  }

  func testNullValueConversion() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("null".utf8)
    )

    XCTAssertNil(value.stringValue)
    XCTAssertNil(value.intValue)
    XCTAssertNil(value.boolValue)
  }

  func testDoubleValueStringConversionDoesNotTruncateFractionalIntegers() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("12.5".utf8)
    )

    XCTAssertEqual(value.stringValue, "12.5")
    XCTAssertNil(value.intValue)
    XCTAssertNil(value.boolValue)
  }

  func testDoubleValueIntConversionAcceptsWholeNumbers() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("12.0".utf8)
    )

    XCTAssertEqual(value.intValue, 12)
  }

  func testDoubleValueIntConversionRejectsOutOfRangeValues() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("1e100".utf8)
    )

    XCTAssertNil(value.intValue)
  }

  func testBoolValueRejectsStringAndNumericValues() throws {
    let decoder = JSONDecoder()
    let falseValue = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("\" false \\n\"".utf8)
    )
    let numericValue = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("1".utf8)
    )

    XCTAssertNil(falseValue.boolValue)
    XCTAssertNil(numericValue.boolValue)
    XCTAssertNil(LemonSqueezyLicenseAPIValue.bool(true).stringValue)
    XCTAssertNil(LemonSqueezyLicenseAPIValue.null.intValue)
  }

  func testRejectsNestedObjectValue() throws {
    let decoder = JSONDecoder()
    XCTAssertThrowsError(
      try decoder.decode(
        LemonSqueezyLicenseAPIValue.self,
        from: Data("{\"key\":\"value\"}".utf8)
      )
    )
  }

  func testRejectsArrayValue() throws {
    let decoder = JSONDecoder()
    XCTAssertThrowsError(
      try decoder.decode(
        LemonSqueezyLicenseAPIValue.self,
        from: Data("[1,\"two\",false]".utf8)
      )
    )
  }

  func testIntValueRejectsNumericStrings() throws {
    let decoder = JSONDecoder()
    let value = try decoder.decode(
      LemonSqueezyLicenseAPIValue.self,
      from: Data("\" 123 \\n\"".utf8)
    )

    XCTAssertNil(value.intValue)
  }
}
